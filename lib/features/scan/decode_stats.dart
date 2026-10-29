import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:blast_qr/debug_channel.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Camera, decoder and transfer numbers for the debug page, kept for the last
/// few transfers.
class DecodeStats extends ChangeNotifier {
  DecodeStats._();

  static final instance = DecodeStats._();

  static const _kept = 5;

  /// Settings the scanner opens the camera with.
  String? camera;

  /// Keep a few camera frames per transfer, to look at or share. Off by
  /// default, as each transfer then holds several MB.
  bool saveFrames = false;

  void updateSaveFrames(bool value) {
    saveFrames = value;
    notifyListeners();
  }

  /// Newest first.
  final List<TransferStats> transfers = [];

  TransferStats? _current;
  Timer? _sampler;

  /// Codes read from the frame being handled; reported before the frame.
  int _frameCodes = 0;

  /// The transfer being received right now, if any.
  TransferStats? get current => _current;

  void startTransfer(int size) {
    _current = TransferStats(camera: camera ?? '-', size: size);
    transfers.insert(0, _current!);
    if (transfers.length > _kept) transfers.removeLast();
    _startSampling(_current!);
    notifyListeners();
  }

  // Only iOS reports exposure and focus.
  void _startSampling(TransferStats transfer) {
    _sampler?.cancel();
    if (!Platform.isIOS) return;
    Future<void> sample() async {
      final state = await DebugChannel.cameraState().catchError((_) => null);
      if (state != null && identical(transfer, _current)) {
        transfer.cameraSamples.add(state);
      }
    }

    sample();
    _sampler = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => sample(),
    );
  }

  /// All the data has arrived.
  void completeTransfer() {
    _current?.completed = true;
    _current?.ended = DateTime.now();
    _current = null;
    _sampler?.cancel();
    notifyListeners();
  }

  /// Stops counting towards the current transfer, finished or not.
  void endTransfer() {
    _current?.ended = DateTime.now();
    _current = null;
    _sampler?.cancel();
    notifyListeners();
  }

  void record(Duration? decodeTime, CameraImage image) {
    final codes = _frameCodes;
    _frameCodes = 0;
    final current = _current;
    if (current == null) return;
    current._recordFrame(decodeTime);
    if (saveFrames && decodeTime != null) {
      current._maybeSaveFrame(image, codes, notifyListeners);
    }
    notifyListeners();
  }

  /// Codes read from one camera frame, repeats included.
  void recordCodesRead(int count) {
    _frameCodes = count;
    final current = _current;
    if (current == null || count == 0) return;
    current.framesWithCode++;
    current.codesRead += count;
    if (count > current.maxCodesPerFrame) current.maxCodesPerFrame = count;
    notifyListeners();
  }

  /// A RaptorQ packet read for the current transfer, repeats included.
  void recordPacket(Uint8List packet) {
    _current?._recordPacket(packet);
  }

  /// A code the transfer hadn't seen before.
  void recordNewCode(int bytes) {
    final current = _current;
    if (current == null) return;
    current._recordNewCode(bytes);
    notifyListeners();
  }

  void clear() {
    transfers.clear();
    _current = null;
    _sampler?.cancel();
    notifyListeners();
  }
}

class TransferStats {
  TransferStats({required this.camera, required this.size})
    : started = DateTime.now();

  // A longer gap between two frames means the camera was off, so it doesn't
  // count as time spent scanning. Likewise for two new codes and receiving.
  static const _maxGap = Duration(seconds: 1);

  final String camera;
  final int size;
  final DateTime started;
  DateTime? ended;
  bool completed = false;

  /// From the first code to all data received, or to when it stopped.
  Duration get duration => (ended ?? DateTime.now()).difference(started);

  int skipped = 0;
  Duration scanTime = Duration.zero;
  final List<int> _decodeMicros = [];
  DateTime? _lastFrame;

  int framesWithCode = 0;
  int codesRead = 0;

  /// The most codes read from one frame. Codes don't say how many the sender
  /// shows at once, so in grid mode this stands in for the grid size.
  int maxCodesPerFrame = 0;
  int newCodes = 0;
  int newBytes = 0;

  // The sender numbers packets in the order it shows them: source packets,
  // then repair packets, each new. In a single-block transfer (anything under
  // about 150 MB) that number is the packet's symbol id, so every id between
  // the first and last one caught was shown.
  final Set<int> _caughtIds = {};
  int? _firstId;
  int? _lastId;
  bool _multiBlock = false;

  /// Codes read out of the ones the sender showed while receiving; null when
  /// that can't be told.
  int? get codesShown =>
      _multiBlock || _firstId == null ? null : _lastId! - _firstId! + 1;
  int get codesCaught => _caughtIds.length;

  /// Close to the most a transfer can get: nearly every code shown was read.
  bool get nearOptimal {
    final shown = codesShown;
    return completed &&
        shown != null &&
        shown >= 20 &&
        codesCaught >= 0.85 * shown;
  }

  void _recordPacket(Uint8List packet) {
    if (packet.length < 4) return;
    if (packet[0] != 0) {
      _multiBlock = true;
      return;
    }
    final id = (packet[1] << 16) | (packet[2] << 8) | packet[3];
    _caughtIds.add(id);
    _firstId = _firstId == null ? id : min(_firstId!, id);
    _lastId = _lastId == null ? id : max(_lastId!, id);
  }

  Duration receiveTime = Duration.zero;
  DateTime? _lastNewCode;

  /// iOS only, a few per second while receiving.
  final List<CameraSample> cameraSamples = [];

  /// A few camera frames spread over the transfer, mostly ones with fewer
  /// codes read than the best frame, to see what the decoder was given.
  final List<SavedFrame> savedFrames = [];

  static const _maxFailedFrames = 8;
  static const _maxReadFrames = 2;
  static const _failedFrameGap = Duration(milliseconds: 300);
  static const _readFrameGap = Duration(seconds: 1);
  DateTime? _lastFailedSave;
  DateTime? _lastReadSave;

  int get decoded => _decodeMicros.length;
  int get frames => decoded + skipped;

  double get cameraFps => _perSecond(frames, scanTime);
  double get decodedFps => _perSecond(decoded, scanTime);
  double get newCodesPerSecond => _perSecond(newCodes, receiveTime);
  double get newBytesPerSecond => _perSecond(newBytes, receiveTime);

  /// Sorted decode times, in microseconds.
  List<int> sortedDecodeMicros() => List.of(_decodeMicros)..sort();

  void _recordFrame(Duration? decodeTime) {
    final now = DateTime.now();
    scanTime += _gap(_lastFrame, now);
    _lastFrame = now;
    if (decodeTime == null) {
      skipped++;
    } else {
      _decodeMicros.add(decodeTime.inMicroseconds);
    }
  }

  void _maybeSaveFrame(CameraImage image, int codes, VoidCallback onSaved) {
    final hadCode = codes > 0 && codes >= maxCodesPerFrame;
    final now = DateTime.now();
    final saved = savedFrames.where((f) => f.hadCode == hadCode).length;
    final last = hadCode ? _lastReadSave : _lastFailedSave;
    if (saved >= (hadCode ? _maxReadFrames : _maxFailedFrames) ||
        (last != null &&
            now.difference(last) <
                (hadCode ? _readFrameGap : _failedFrameGap))) {
      return;
    }
    final grey = _GreyFrame.from(image);
    if (grey == null) return;
    if (hadCode) {
      _lastReadSave = now;
    } else {
      _lastFailedSave = now;
    }
    final at = now.difference(started);
    compute(_encodePng, grey).then((png) {
      savedFrames.add(
        SavedFrame(hadCode: hadCode, codes: codes, at: at, png: png),
      );
      savedFrames.sort((a, b) => a.at.compareTo(b.at));
      onSaved();
    });
  }

  void _recordNewCode(int bytes) {
    final now = DateTime.now();
    receiveTime += _gap(_lastNewCode, now);
    _lastNewCode = now;
    newCodes++;
    newBytes += bytes;
  }

  static double _perSecond(int count, Duration time) => time == Duration.zero
      ? 0
      : count / (time.inMicroseconds / Duration.microsecondsPerSecond);

  static Duration _gap(DateTime? last, DateTime now) {
    if (last == null) return Duration.zero;
    final gap = now.difference(last);
    return gap < _maxGap ? gap : Duration.zero;
  }
}

class SavedFrame {
  SavedFrame({
    required this.hadCode,
    required this.codes,
    required this.at,
    required this.png,
  });

  /// Read as many codes as the best frame of the transfer so far.
  final bool hadCode;
  final int codes;

  /// Time since the transfer started.
  final Duration at;
  final Uint8List png;
}

/// One camera frame reduced to its brightness, which is all the decoder uses.
class _GreyFrame {
  _GreyFrame(this.bytes, this.width, this.height, this.bytesPerRow, this.bgra);

  final Uint8List bytes;
  final int width;
  final int height;
  final int bytesPerRow;
  final bool bgra;

  static _GreyFrame? from(CameraImage image) {
    final plane = image.planes.first;
    final bgra = image.format.group == ImageFormatGroup.bgra8888;
    if (!bgra && image.format.group != ImageFormatGroup.yuv420) return null;
    // Copied, as the camera may reuse the buffer.
    return _GreyFrame(
      Uint8List.fromList(plane.bytes),
      image.width,
      image.height,
      plane.bytesPerRow,
      bgra,
    );
  }
}

Uint8List _encodePng(_GreyFrame f) {
  final grey = Uint8List(f.width * f.height);
  for (var y = 0; y < f.height; y++) {
    final row = y * f.bytesPerRow;
    for (var x = 0; x < f.width; x++) {
      if (f.bgra) {
        final i = row + x * 4;
        grey[y * f.width + x] =
            (f.bytes[i + 2] * 77 + f.bytes[i + 1] * 150 + f.bytes[i] * 29) >> 8;
      } else {
        grey[y * f.width + x] = f.bytes[row + x];
      }
    }
  }
  return img.encodePng(
    img.Image.fromBytes(
      width: f.width,
      height: f.height,
      bytes: grey.buffer,
      numChannels: 1,
    ),
  );
}
