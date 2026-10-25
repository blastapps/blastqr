import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:blast_qr/crypto/transfer_crypto.dart';
import 'package:blast_qr/features/send/helpers/qr_lookup_table.dart';
import 'package:blast_qr/model/blast_qrcode_data.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blast_qr/model/image_compression_settings.dart';
import 'package:blast_qr/model/transfer_container.dart';
import 'package:blast_qr/raptorq/raptorq_streaming_encoder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:qr/qr.dart';

/// One rendered QR frame. [seq] is its position in the stream (0, 1, 2, ...).
typedef QrPixelData = ({int seq, int moduleCount, Uint8List pixels});

typedef _WorkerInit =
    ({SendPort setup, SendPort results, Uint8List header, int qrVersion});

/// Render worker: turns packets into RGBA pixel buffers until it gets `null`.
void _renderWorker(_WorkerInit init) {
  final requests = ReceivePort();
  init.setup.send(requests.sendPort);

  requests.listen((message) {
    if (message == null) {
      requests.close();
      return;
    }
    final (seq, packet) = message as (int, Uint8List);
    final (moduleCount, pixels) = _renderQrFrame(
      init.header,
      packet,
      init.qrVersion,
    );
    // TransferableTypedData hands the buffer over without copying.
    init.results.send((seq, moduleCount, TransferableTypedData.fromList([pixels])));
  });
}

/// Builds one frame (shared header + RaptorQ packet) and renders it to RGBA
/// pixels, one pixel per module.
(int, Uint8List) _renderQrFrame(
  Uint8List header,
  Uint8List packet,
  int qrVersion,
) {
  final combined = Uint8List(header.length + packet.length)
    ..setAll(0, header)
    ..setAll(header.length, packet);

  final qrCode = QrCode(qrVersion, QrErrorCorrectLevel.L);
  qrCode.addByteData(combined.buffer.asByteData());
  // Fixed mask: skips evaluating all 8 masks, much faster to generate.
  final qrImage = QrImage.withMaskPattern(qrCode, 3);

  final moduleCount = qrImage.moduleCount;
  final pixels = Uint8List(moduleCount * moduleCount * 4);
  for (var row = 0; row < moduleCount; row++) {
    for (var col = 0; col < moduleCount; col++) {
      final offset = (row * moduleCount + col) * 4;
      if (qrImage.isDark(row, col)) {
        pixels[offset + 3] = 255;
      } else {
        pixels[offset] = 255;
        pixels[offset + 1] = 255;
        pixels[offset + 2] = 255;
        pixels[offset + 3] = 255;
      }
    }
  }
  return (moduleCount, pixels);
}

Uint8List _gzipCompress(Uint8List original) {
  return gzip.encode(original) as Uint8List;
}

/// An endless stream of rendered QR frames for one file.
///
/// Frames are generated on demand: the source stays [lookahead] frames ahead
/// of what the display has used (see [markConsumed]), so memory stays small
/// however long the transfer runs. Frames can arrive slightly out of order
/// (two render workers); use [QrPixelData.seq] to order them.
class QrFrameSource {
  /// Frames kept ready or in progress beyond those already shown. About
  /// 0.5–4 s of playback depending on fps and grid size.
  static const int lookahead = 90;

  /// One background isolate renders a version-40 frame in ~3–10 ms, which
  /// can fall short of 6 codes × 30 fps, so two share the work.
  static const int workerCount = 2;

  final RaptorqStreamingEncoder _encoder;
  final List<Isolate> _isolates;
  final List<SendPort> _workers;
  final ReceivePort _results;
  final _frames = StreamController<QrPixelData>();
  final _pending = Queue<Uint8List>();

  int _requested = 0;
  int _consumed = 0;
  bool _pumping = false;
  bool _disposed = false;

  QrFrameSource._(this._encoder, this._isolates, this._workers, this._results) {
    _results.listen((message) {
      if (_disposed) return;
      final (seq, moduleCount, pixels) =
          message as (int, int, TransferableTypedData);
      _frames.add((
        seq: seq,
        moduleCount: moduleCount,
        pixels: pixels.materialize().asUint8List(),
      ));
    });
    _pump();
  }

  /// Rendered frames, endlessly.
  Stream<QrPixelData> get frames => _frames.stream;

  /// Number of source packets (K). The receiver needs about this many frames.
  int get sourceCount => _encoder.sourceCount;

  /// Tells the source that frames up to [count] (exclusive) have been shown,
  /// so it can render more.
  void markConsumed(int count) {
    if (count <= _consumed) return;
    _consumed = count;
    _pump();
  }

  Future<void> _pump() async {
    if (_pumping) return;
    _pumping = true;
    try {
      while (!_disposed && _requested - _consumed < lookahead) {
        if (_pending.isEmpty) {
          _pending.addAll(await _encoder.nextPackets(32));
          if (_disposed) return;
        }
        final seq = _requested++;
        _workers[seq % _workers.length].send((seq, _pending.removeFirst()));
      }
    } finally {
      _pumping = false;
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final worker in _workers) {
      worker.send(null);
    }
    for (final isolate in _isolates) {
      isolate.kill(priority: Isolate.beforeNextEvent);
    }
    _results.close();
    _frames.close();
    _encoder.dispose();
  }
}

/// Builds the transfer object (see [TransferContainer]): the metadata block
/// with [fileName], then [content], gzipped as a whole if [tryGzip] and only
/// if that makes it smaller, then encrypted if a [password] is given.
/// Returns whether gzip was kept.
Future<({Uint8List bytes, bool gzipped})> buildTransferObject({
  required String fileName,
  required Uint8List content,
  required bool tryGzip,
  String? password,
  bool isBundle = false,
}) async {
  final metadata = TransferContainer.encodeMetadata(
    fileName: fileName,
    isBundle: isBundle,
  );
  var bytes = Uint8List(metadata.length + content.length)
    ..setAll(0, metadata)
    ..setAll(metadata.length, content);

  var gzipped = false;
  if (tryGzip) {
    final compressed = await compute(_gzipCompress, bytes);
    // Only keep gzip when it helps. This also keeps files near the size
    // limit from growing past what the u32 header can describe.
    if (compressed.length < bytes.length) {
      bytes = compressed;
      gzipped = true;
    }
  }
  // Encrypt last: compressed ciphertext wouldn't shrink, and the filename
  // in the metadata ends up encrypted too.
  if (password != null) {
    bytes = await TransferCrypto.encrypt(bytes, password);
  }
  return (bytes: bytes, gzipped: gzipped);
}

/// The header shared by every frame of one send, with a new random session
/// id unless [sessionId] is given.
Uint8List buildFrameHeader({
  required bool gzipped,
  required bool encrypted,
  required int transferLength,
  required int symbolSize,
  int? sessionId,
}) {
  return BlastQrcodeData.buildHeader(
    flags:
        (gzipped ? BlastQrcodeData.flagGzip : 0) |
        (encrypted ? BlastQrcodeData.flagEncrypted : 0),
    kind: BlastQrcodeData.kindFile,
    // Random per send, so receivers can tell a new transfer from an old one.
    sessionId: sessionId ?? 1 + Random.secure().nextInt(0xFFFF),
    transferLength: transferLength,
    symbolSize: symbolSize,
  );
}

class FileQrEncoder {
  const FileQrEncoder._();

  /// Prepares [file] for sending and starts an endless frame stream.
  ///
  /// The caller must [QrFrameSource.dispose] the result.
  static Future<QrFrameSource> start(
    FileWrapper file,
    int mtu, {
    ImageCompressionSettings? icSettings,
    String? password,
    String? fileName,
    bool isBundle = false,
    void Function(int)? onCompressedSize,
  }) async {
    var bytes = await file.file.readAsBytes();
    var gzipped = !file.type.isPrecompressed;
    var fileExtension = file.type.extension;
    var reencoded = false;

    // Image compression. The settings can be passed for any file (e.g. with
    // "always compress images"), so only images are re-encoded, and only a
    // re-encoded image takes the output format's extension.
    if (icSettings != null && file.type.allowsImageCompression) {
      final compressedImage = await compressImage(bytes, icSettings);
      if (compressedImage != null) {
        bytes = compressedImage;
        gzipped = false;
        fileExtension = icSettings.outputFormat.extension ?? fileExtension;
        reencoded = true;
      }
    }

    // A renamed file keeps the name as typed, except that a re-encoded image
    // still takes the output format's extension.
    final sentName = switch (fileName) {
      null => '${file.nameWithoutExtension}.$fileExtension',
      _ when reencoded => '${p.basenameWithoutExtension(fileName)}.$fileExtension',
      _ => fileName,
    };

    final transfer = await buildTransferObject(
      fileName: sentName,
      content: bytes,
      tryGzip: gzipped,
      password: password,
      isBundle: isBundle,
    );
    bytes = transfer.bytes;

    final actualTransferSize = bytes.length;
    debugPrint('Compressed file: ${file.size} -> $actualTransferSize');
    onCompressedSize?.call(actualTransferSize);

    final encoder = RaptorqStreamingEncoder(mtu: mtu);
    await encoder.init(bytes);

    final header = buildFrameHeader(
      gzipped: transfer.gzipped,
      encrypted: password != null,
      transferLength: actualTransferSize,
      symbolSize: encoder.symbolSize,
    );
    final qrVersion = pickQrVersion(mtu);
    debugPrint('Picked QR version: $qrVersion for mtu $mtu');

    final results = ReceivePort();
    final isolates = <Isolate>[];
    final workers = <SendPort>[];
    for (var i = 0; i < QrFrameSource.workerCount; i++) {
      final setup = ReceivePort();
      isolates.add(
        await Isolate.spawn(_renderWorker, (
          setup: setup.sendPort,
          results: results.sendPort,
          header: header,
          qrVersion: qrVersion,
        )),
      );
      workers.add(await setup.first as SendPort);
    }

    return QrFrameSource._(encoder, isolates, workers, results);
  }

  /// QR version for an MTU setting: the smallest version that holds the
  /// MTU, plus one for the header and packet id.
  static int pickQrVersion(int payloadBytes) {
    for (final entry in qrByteCapacityL.entries) {
      if (payloadBytes <= entry.value) {
        return entry.key < 40 ? entry.key + 1 : 40;
      }
    }
    return 40;
  }

  static Future<Uint8List?> compressImage(
    Uint8List bytes,
    ImageCompressionSettings settings,
  ) async {
    try {
      return await FlutterImageCompress.compressWithList(
        bytes,
        minHeight: settings.minSize,
        minWidth: settings.minSize,
        quality: settings.quality,
        format: settings.outputFormat.toCompressFormat(),
        keepExif: true,
      );
    } catch (e) {
      debugPrint('Image compression failed. Reverting to file compression');
      return null;
    }
  }
}
