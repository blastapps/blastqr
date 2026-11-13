import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:blast_qr/app_preferences.dart';
import 'package:blast_qr/crypto/transfer_crypto.dart';
import 'package:blast_qr/features/send/helpers/video_compression.dart';
import 'package:blast_qr/features/send/send_options.dart';
import 'package:blast_qr/file_bundle.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blast_qr/model/image_compression_settings.dart';
import 'package:blast_qr/model/transfer_container.dart';
import 'package:blast_qr/model/video_quality.dart';
import 'package:blast_qr/temp_files.dart';
import 'package:blastqr_video/blastqr_video.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

/// Sends larger than this get a warning first.
const largeTransferBytes = 2500000;

/// Photos and videos up to this size aren't worth re-encoding.
const minCompressibleMediaBytes = 400000;

/// Set by [detectVideoCompression]. Until then, videos are sent as they are.
bool videoCompressionSupported = false;

/// Checks once at startup whether videos can be compressed: always on
/// phones and macOS, on Linux only with ffmpeg.
Future<void> detectVideoCompression() async {
  videoCompressionSupported = await BlastqrVideo.isSupported();
}

bool isCompressibleImage(FileWrapper file) =>
    file.type.allowsImageCompression && file.size > minCompressibleMediaBytes;

/// Whether it's worth re-encoding is only known once it's read, see
/// [encodeSettingsFor].
bool isCompressibleVideo(FileWrapper file) =>
    videoCompressionSupported &&
    AppPreferences.videoQuality != VideoQuality.original &&
    file.type.isVideo &&
    file.size > minCompressibleMediaBytes;

bool isCompressibleMedia(FileWrapper file) =>
    isCompressibleImage(file) || isCompressibleVideo(file);

/// The fewest bytes [files] could be sent in once compressed: photos may
/// shrink to almost nothing, videos to at most [maxVideoBytes].
int minSendBytes(List<FileWrapper> files) => files.fold(
  0,
  (sum, f) =>
      sum +
      switch (f) {
        _ when isCompressibleImage(f) => 0,
        _ when isCompressibleVideo(f) => min(f.size, maxVideoBytes),
        _ => f.size,
      },
);

/// Compressed photos come out at about this size with the default settings.
const _estimatedImageBytes = 400000;

/// About how many bytes [files] are sent in, before gzip. [videos] has
/// what's known of the videos, by path, from [BlastqrVideo.probe]; until a
/// video is known it counts as at most [maxVideoBytes].
int estimateSendBytes(
  List<FileWrapper> files, {
  required bool compressMedia,
  Map<String, VideoInfo> videos = const {},
}) => files.fold(0, (sum, f) {
  if (!compressMedia) return sum + f.size;
  if (isCompressibleImage(f)) return sum + min(f.size, _estimatedImageBytes);
  if (!isCompressibleVideo(f)) return sum + f.size;
  final info = videos[f.file.path];
  if (info == null) return sum + min(f.size, maxVideoBytes);
  final settings = encodeSettingsFor(
    info,
    sourceBytes: f.size,
    quality: AppPreferences.videoQuality,
  );
  return sum +
      (settings == null ? f.size : estimatedVideoBytes(info, settings));
});

/// A transfer object ready to show as QR codes (see [writeTransferObject]),
/// kept in a temp [file] so it isn't held in memory while it's sent.
class PreparedTransfer {
  const PreparedTransfer({
    required this.files,
    required this.name,
    required this.file,
    required this.length,
    required this.gzipped,
    required this.password,
    required this.compressed,
  });

  /// The files picked, to show what's being sent.
  final List<FileWrapper> files;

  /// The name the receiver saves a single file as, or the bundle's name.
  final String name;

  final File file;
  final int length;
  final bool gzipped;

  /// Set when encrypted, to show to the user.
  final String? password;

  /// Whether photos or videos were compressed, as the user asked. Such
  /// sends skip the long transfer prompt: the user already made them as
  /// small as they can be.
  final bool compressed;

  bool get isBundle => files.length > 1;

  Future<void> delete() async {
    try {
      await file.delete();
    } on FileSystemException catch (_) {}
  }
}

/// Builds what [files] are sent as: photos and videos compressed if
/// [SendOptions.compressMedia], several files zipped into one, the name
/// applied, then gzipped if that helps and encrypted if there's a password.
///
/// Video compression is reported to [onProgress] from 0 to 1, and stops
/// with [VideoCompressionCancelled] once [cancel] completes.
Future<PreparedTransfer> prepareTransfer(
  List<FileWrapper> files,
  SendOptions options, {
  required ImageCompressionSettings imageSettings,
  void Function(double progress)? onProgress,
  Future<void>? cancel,
}) async {
  final compress = options.compressMedia && files.any(isCompressibleMedia);
  final content = files.length > 1
      ? await _bundle(
          files,
          compress: compress,
          imageSettings: imageSettings,
          onProgress: onProgress,
          cancel: cancel,
        )
      : await _singleFile(
          files.single,
          renamed: options.fileName,
          compress: compress,
          imageSettings: imageSettings,
          onProgress: onProgress,
          cancel: cancel,
        );
  final file = File(
    '${(await appTempDirectory()).path}/'
    'transfer-${DateTime.now().microsecondsSinceEpoch}.bin',
  );
  final ({int length, bool gzipped}) transfer;
  try {
    transfer = await writeTransferObject(
      file.path,
      fileName: content.name,
      content: content.bytes,
      contentPath: content.path,
      tryGzip: content.tryGzip,
      password: options.password,
      isBundle: files.length > 1,
    );
  } finally {
    if (content.temporary) await File(content.path!).delete();
  }
  debugPrint(
    'Prepared ${content.name}: '
    '${files.fold(0, (sum, f) => sum + f.size)} -> ${transfer.length}',
  );
  return PreparedTransfer(
    files: files,
    name: content.name,
    file: file,
    length: transfer.length,
    gzipped: transfer.gzipped,
    password: options.password,
    compressed: compress,
  );
}

/// Either [bytes] in memory or the file at [path], deleted once read if
/// [temporary].
typedef _Content = ({
  String name,
  Uint8List? bytes,
  String? path,
  bool temporary,
  bool tryGzip,
});

/// A re-encoded file takes its new format's extension, also when
/// [renamed].
Future<_Content> _singleFile(
  FileWrapper file, {
  required String? renamed,
  required bool compress,
  required ImageCompressionSettings imageSettings,
  void Function(double progress)? onProgress,
  Future<void>? cancel,
}) async {
  String reencodedName(String extension) =>
      '${p.basenameWithoutExtension(renamed ?? file.name)}.$extension';

  if (compress && isCompressibleVideo(file)) {
    final video = await compressVideo(
      file,
      onProgress: onProgress,
      cancel: cancel,
    );
    if (video != null) {
      return (
        name: reencodedName(video.extension),
        bytes: null,
        path: video.file.path,
        temporary: false,
        tryGzip: false,
      );
    }
  }
  if (compress && isCompressibleImage(file)) {
    final image = await _compressImage(
      await file.file.readAsBytes(),
      imageSettings,
    );
    if (image != null) {
      return (
        name: reencodedName(
          imageSettings.outputFormat.extension ?? file.type.extension,
        ),
        bytes: image,
        path: null,
        temporary: false,
        tryGzip: false,
      );
    }
  }
  return (
    name: renamed ?? file.name,
    bytes: null,
    path: file.file.path,
    temporary: false,
    tryGzip: !file.type.isPrecompressed,
  );
}

/// Writes the transfer object (see [TransferContainer]) to [path]: the
/// metadata block with [fileName], then the content ([content], or the file
/// at [contentPath]), gzipped as a whole if [tryGzip] and only if that makes
/// it smaller, then encrypted if a [password] is given. Returns its length
/// and whether gzip was kept. Nothing is left at [path] if it fails.
///
/// Written in chunks, so even large files never sit in memory whole.
Future<({int length, bool gzipped})> writeTransferObject(
  String path, {
  required String fileName,
  Uint8List? content,
  String? contentPath,
  required bool tryGzip,
  String? password,
  bool isBundle = false,
}) async {
  assert((content == null) != (contentPath == null));
  final metadata = TransferContainer.encodeMetadata(
    fileName: fileName,
    isBundle: isBundle,
  );
  final plainPath = password == null ? path : '$path.plain';
  try {
    final (:length, :gzipped) = await Isolate.run(() {
      ({int read, int written}) write({required bool gzip}) =>
          _writeChunked(plainPath, metadata, content, contentPath, gzip: gzip);
      if (tryGzip) {
        final (:read, :written) = write(gzip: true);
        // Only keep gzip when it helps. This also keeps files near the size
        // limit from growing past what the u32 header can describe.
        if (written < read) return (length: written, gzipped: true);
      }
      return (length: write(gzip: false).written, gzipped: false);
    });
    if (password == null) return (length: length, gzipped: gzipped);
    // Encrypt last: compressed ciphertext wouldn't shrink, and the filename
    // in the metadata ends up encrypted too.
    await TransferCrypto.encryptFile(plainPath, path, password);
    return (length: await File(path).length(), gzipped: gzipped);
  } catch (_) {
    await _deleteIfExists(path);
    rethrow;
  } finally {
    if (password != null) await _deleteIfExists(plainPath);
  }
}

Future<void> _deleteIfExists(String path) async {
  final file = File(path);
  if (await file.exists()) await file.delete();
}

/// Writes [metadata] then the content to [path], through gzip if [gzip],
/// 1 MB at a time. Returns the bytes read and written.
({int read, int written}) _writeChunked(
  String path,
  Uint8List metadata,
  Uint8List? content,
  String? contentPath, {
  required bool gzip,
}) {
  final output = File(path).openSync(mode: FileMode.write);
  try {
    final fileSink = _FileSink(output);
    final sink = gzip
        ? GZipCodec().encoder.startChunkedConversion(fileSink)
        : fileSink;
    sink.add(metadata);
    var read = metadata.length;
    if (content != null) {
      sink.add(content);
      read += content.length;
    } else {
      final input = File(contentPath!).openSync();
      try {
        final buffer = Uint8List(1 << 20);
        int count;
        // Each chunk is written before add returns, so the buffer is reused.
        while ((count = input.readIntoSync(buffer)) > 0) {
          sink.add(Uint8List.sublistView(buffer, 0, count));
          read += count;
        }
      } finally {
        input.closeSync();
      }
    }
    sink.close();
    return (read: read, written: fileSink.written);
  } finally {
    output.closeSync();
  }
}

/// Writes each chunk straight to a file.
class _FileSink implements Sink<List<int>> {
  _FileSink(this._file);

  final RandomAccessFile _file;
  int written = 0;

  @override
  void add(List<int> chunk) {
    _file.writeFromSync(chunk);
    written += chunk.length;
  }

  @override
  void close() {}
}

/// Zips [files], compressing photos and videos first if [compress], as for
/// a single file. Video compression is reported to [onProgress] from 0 to 1
/// for all videos together.
Future<_Content> _bundle(
  List<FileWrapper> files, {
  required bool compress,
  required ImageCompressionSettings imageSettings,
  void Function(double progress)? onProgress,
  Future<void>? cancel,
}) async {
  final videos = compress
      ? files.where(isCompressibleVideo).toList()
      : const <FileWrapper>[];
  final videoBytes = videos.fold(0, (sum, f) => sum + f.size);
  var videoBytesDone = 0;
  final entries = <BundleEntry>[];
  for (final file in files) {
    if (compress && isCompressibleImage(file)) {
      final bytes = await _compressImage(
        await file.file.readAsBytes(),
        imageSettings,
      );
      if (bytes != null) {
        final extension =
            imageSettings.outputFormat.extension ?? file.type.extension;
        entries.add((
          name: '${file.nameWithoutExtension}.$extension',
          path: null,
          bytes: bytes,
        ));
        continue;
      }
    }
    if (videos.contains(file)) {
      final done = videoBytesDone;
      final compressed = await compressVideo(
        file,
        onProgress: onProgress == null
            ? null
            : (p) => onProgress((done + p * file.size) / videoBytes),
        cancel: cancel,
      );
      videoBytesDone += file.size;
      if (compressed != null) {
        entries.add((
          name: compressed.name,
          path: compressed.file.path,
          bytes: null,
        ));
        continue;
      }
    }
    entries.add((name: file.name, path: file.file.path, bytes: null));
  }

  final directory = Directory('${(await appTempDirectory()).path}/bundles');
  await directory.create(recursive: true);
  final timestamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
  final zip = File('${directory.path}/blastqr-$timestamp.zip');
  await writeBundle(entries, zip.path);
  return (
    name: zip.uri.pathSegments.last,
    bytes: null,
    path: zip.path,
    temporary: true,
    tryGzip: true,
  );
}

/// Re-encodes a photo with [settings]. Null if that fails or isn't smaller.
Future<Uint8List?> _compressImage(
  Uint8List bytes,
  ImageCompressionSettings settings,
) async {
  try {
    final compressed = await FlutterImageCompress.compressWithList(
      bytes,
      minHeight: settings.minSize,
      minWidth: settings.minSize,
      quality: settings.quality,
      format: settings.outputFormat.toCompressFormat(),
      keepExif: true,
    );
    if (compressed.length >= bytes.length) {
      debugPrint('Compressed image is not smaller. Sending original');
      return null;
    }
    return compressed;
  } catch (e) {
    debugPrint('Image compression failed. Reverting to file compression');
    return null;
  }
}
