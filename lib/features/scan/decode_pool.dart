import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_zxing/flutter_zxing.dart';

/// Decodes camera frames on several isolates at once. flutter_zxing has a
/// single decoding isolate, which caps scanning at one frame per decode time
/// (about 30 FPS for dense codes on an iPhone 17) however fast the camera is.
class DecodePool {
  DecodePool({int? size}) : size = size ?? defaultSize;

  /// Half the cores, leaving the rest for the camera, UI and file assembly.
  static int get defaultSize => (Platform.numberOfProcessors ~/ 2).clamp(1, 4);

  final int size;
  final _idle = <_Worker>[];
  final _all = <_Worker>[];
  bool _stopped = false;

  /// Whether a frame handed to [decode] now would start right away.
  bool get hasIdleWorker => _idle.isNotEmpty;

  /// Each worker is used as soon as it's ready.
  Future<void> start() => Future.wait([
    for (var i = 0; i < size; i++)
      _Worker.spawn().then((worker) {
        if (_stopped) {
          worker.kill();
        } else {
          _all.add(worker);
          _idle.add(worker);
        }
      }),
  ]);

  /// Decodes [image] on an idle worker. Call only when [hasIdleWorker].
  Future<Codes> decode(CameraImage image, DecodeParams params) async {
    final worker = _idle.removeLast();
    try {
      return await worker.decode(image, params);
    } finally {
      if (!_stopped) _idle.add(worker);
    }
  }

  void stop() {
    _stopped = true;
    for (final worker in _all) {
      worker.kill();
    }
    _all.clear();
    _idle.clear();
  }
}

class _Worker {
  _Worker._(this._isolate, this._jobs, this._replies, Stream<Object?> replies) {
    replies.listen(_onReply);
  }

  static Future<_Worker> spawn() async {
    final replies = ReceivePort();
    final stream = replies.asBroadcastStream();
    final isolate = await Isolate.spawn(
      _main,
      replies.sendPort,
      debugName: 'DecodeWorker',
    );
    final jobs = await stream.first as SendPort;
    return _Worker._(isolate, jobs, replies, stream);
  }

  final Isolate _isolate;
  final SendPort _jobs;
  final ReceivePort _replies;
  Completer<Codes>? _job;

  void _onReply(Object? message) {
    final job = _job;
    _job = null;
    if (job == null) return;
    if (message is Codes) {
      job.complete(message);
    } else {
      job.completeError(Exception(message));
    }
  }

  /// Sends only the first plane: luminance for YUV, all of it for BGRA.
  Future<Codes> decode(CameraImage image, DecodeParams params) {
    final job = _job = Completer<Codes>();
    final plane = image.planes.first;
    _jobs.send((plane.bytes, plane.bytesPerRow, params));
    return job.future;
  }

  void kill() {
    _isolate.kill(priority: Isolate.immediate);
    _replies.close();
    _job?.completeError(StateError('Decoder stopped'));
    _job = null;
  }

  static Future<void> _main(SendPort replies) async {
    final jobs = ReceivePort();
    replies.send(jobs.sendPort);
    await for (final message in jobs) {
      final (bytes, bytesPerRow, params) =
          message as (Uint8List, int, DecodeParams);
      try {
        replies.send(
          zx.readBarcodes(_packed(bytes, bytesPerRow, params), params),
        );
      } catch (e) {
        replies.send('$e');
      }
    }
  }

  /// [bytes] without the padding cameras may add to each row.
  static Uint8List _packed(Uint8List bytes, int bytesPerRow, DecodeParams p) {
    final pixelStride = p.imageFormat == ImageFormat.lum ? 1 : 4;
    final rowLength = p.width * pixelStride;
    if (bytesPerRow == rowLength) return bytes;
    final packed = Uint8List(rowLength * p.height);
    for (var row = 0; row < p.height; row++) {
      packed.setRange(
        row * rowLength,
        (row + 1) * rowLength,
        bytes,
        row * bytesPerRow,
      );
    }
    return packed;
  }
}
