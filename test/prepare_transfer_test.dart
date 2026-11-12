import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:blast_qr/app_preferences.dart';
import 'package:blast_qr/features/send/helpers/video_compression.dart';
import 'package:blast_qr/features/send/prepare_transfer.dart';
import 'package:blast_qr/model/file_extension.dart';
import 'package:blast_qr/model/file_type.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blast_qr/model/image_compression_settings.dart';
import 'package:blast_qr/model/transfer_container.dart';
import 'package:blast_qr/model/video_quality.dart';
import 'package:blastqr_video/blastqr_video.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _mb = 1000000;

FileWrapper _file(String name, int size) {
  final extension = name.split('.').last;
  return FileWrapper(
    file: File(name),
    type: FileType(
      extension: extension,
      mimeType: switch (extension) {
        'jpg' => 'image/jpeg',
        'mp4' => 'video/mp4',
        'pdf' => 'application/pdf',
        _ => 'text/plain',
      },
    ),
    size: size,
    modified: DateTime(2026),
  );
}

FileWrapper _jpg(int size) => _file('photo.jpg', size);
FileWrapper _mp4(int size) => _file('clip.mp4', size);
FileWrapper _pdf(int size) => _file('doc.pdf', size);

/// The name, bundle flag and content a receiver gets from [transfer].
({String? name, bool isBundle, Uint8List content}) _receive(
  PreparedTransfer transfer,
) {
  final bytes = transfer.gzipped
      ? Uint8List.fromList(gzip.decode(transfer.bytes))
      : transfer.bytes;
  final length = ByteData.sublistView(bytes).getUint16(0);
  final metadata = TransferContainer.decodeMetadata(
    bytes.sublist(2, 2 + length),
  );
  return (
    name: metadata.fileName,
    isBundle: metadata.isBundle,
    content: bytes.sublist(2 + length),
  );
}

void main() {
  group('compressible media', () {
    final supported = videoCompressionSupported;
    setUp(() => videoCompressionSupported = true);
    tearDown(() => videoCompressionSupported = supported);

    test('photos and videos up to 400 KB are sent as they are', () {
      expect(isCompressibleImage(_jpg(400000)), isFalse);
      expect(isCompressibleImage(_jpg(400001)), isTrue);
      expect(isCompressibleVideo(_mp4(400000)), isFalse);
      expect(isCompressibleVideo(_mp4(400001)), isTrue);
    });

    test('videos are never compressed where it isn\'t supported', () {
      videoCompressionSupported = false;

      expect(isCompressibleVideo(_mp4(50 * _mb)), isFalse);
    });

    test('videos are never compressed at original quality', () async {
      SharedPreferences.setMockInitialValues({});
      await AppPreferences.setVideoQuality(VideoQuality.original);
      addTearDown(
        () =>
            AppPreferences.setVideoQuality(AppPreferences.defaultVideoQuality),
      );

      expect(isCompressibleVideo(_mp4(50 * _mb)), isFalse);
    });

    test('estimateSendBytes counts what compressing gives', () {
      final files = [_jpg(3 * _mb), _mp4(50 * _mb), _pdf(10)];
      final videos = {
        'clip.mp4': const VideoInfo(
          duration: Duration(seconds: 8),
          width: 1920,
          height: 1080,
          hasAudio: true,
        ),
      };

      expect(
        estimateSendBytes(files, compressMedia: false, videos: videos),
        53 * _mb + 10,
      );
      // A 400 KB photo, 8 s at 400 kbps plus 64 kbps of audio (the default
      // quality), and the PDF.
      expect(
        estimateSendBytes(files, compressMedia: true, videos: videos),
        400000 + 464000 + 10,
      );
      // Until it's read, a video counts as at most the maximum size.
      expect(
        estimateSendBytes(files, compressMedia: true),
        400000 + maxVideoBytes + 10,
      );
    });

    test('minSendBytes counts photos as nothing and videos at most at the '
        'maximum size', () {
      final files = [_jpg(3 * _mb), _mp4(500 * _mb), _mp4(3 * _mb), _pdf(10)];

      expect(minSendBytes(files), maxVideoBytes + 3 * _mb + 10);
    });
  });

  group('prepareTransfer', () {
    late Directory temp;

    setUp(() {
      temp = Directory.systemTemp.createTempSync('prepare_transfer_test');
      PathProviderPlatform.instance = _FakePathProvider(temp.path);
    });

    tearDown(() => temp.deleteSync(recursive: true));

    Future<FileWrapper> write(String name, String content) => (File(
      '${temp.path}/$name',
    )..writeAsStringSync(content)).toFileWrapper();

    Future<PreparedTransfer> prepare(
      List<FileWrapper> files, {
      String? fileName,
    }) => prepareTransfer(files, (
      password: null,
      fileName: fileName,
      compressMedia: true,
    ), imageSettings: ImageCompressionSettings.defaultSettings);

    test('sends a single file under its name, gzipped if it helps', () async {
      final file = await write('notes.txt', 'hello ' * 1000);

      final transfer = await prepare([file]);
      final received = _receive(transfer);

      expect(transfer.gzipped, isTrue);
      expect(transfer.bytes.length, lessThan(file.size));
      expect(transfer.compressed, isFalse);
      expect(transfer.name, 'notes.txt');
      expect(received.name, 'notes.txt');
      expect(received.isBundle, isFalse);
      expect(String.fromCharCodes(received.content), 'hello ' * 1000);
    });

    test('a renamed file is sent under the new name', () async {
      final file = await write('notes.txt', 'hello');

      final transfer = await prepare([file], fileName: 'todo.txt');

      expect(transfer.name, 'todo.txt');
      expect(_receive(transfer).name, 'todo.txt');
    });

    test('several files are sent as one zip, which is then deleted', () async {
      final files = [
        await write('a.txt', 'first'),
        await write('b.txt', 'second'),
      ];

      final transfer = await prepare(files);
      final received = _receive(transfer);
      final zip = ZipDecoder().decodeBytes(received.content);

      expect(transfer.isBundle, isTrue);
      expect(received.isBundle, isTrue);
      expect(received.name, endsWith('.zip'));
      expect(zip.files.map((f) => f.name), ['a.txt', 'b.txt']);
      expect(
        temp.listSync(recursive: true).where((f) => f.path.endsWith('.zip')),
        isEmpty,
      );
    });
  });
}

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.path);

  final String path;

  @override
  Future<String?> getTemporaryPath() async => path;
}
