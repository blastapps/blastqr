import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:record/record.dart';

/// Listens to the microphone and detects the two-tone acoustic acknowledgement
/// signal (880 Hz followed by 1320 Hz) that the receiving device plays when a
/// blastQR transfer completes.
///
/// Uses the Goertzel algorithm for efficient single-frequency power estimation.
/// Detection requires both tones to exceed [_threshold] and appear in the
/// correct order within a [_freq2Timeout] window.
class AcousticAckListener {
  static const int _sampleRate = 16000;
  static const int _frameSize = 1600; // 100 ms per frame at 16 kHz

  /// Fundamental frequencies matching [SoundFeedbackService._buildSequentialWav].
  static const double _freq1 = 880.0; // A5
  static const double _freq2 = 1320.0; // E6

  /// Minimum raw Goertzel power to count a tone as present.
  /// Increase if false positives occur in noisy environments.
  static const double _threshold = 5.0;

  /// Window after detecting freq1 during which freq2 must appear.
  static const Duration _freq2Timeout = Duration(milliseconds: 700);

  // Precomputed Goertzel coefficients.
  final double _coeff1;
  final double _coeff2;

  final _controller = StreamController<void>.broadcast();

  /// Fires each time the two-tone sequence is detected.
  Stream<void> get onDetected => _controller.stream;

  final _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _audioSub;

  final _buffer = <int>[];

  _DetectionState _state = _DetectionState.idle;
  DateTime? _freq1At;

  AcousticAckListener()
    : _coeff1 = _goertzelCoeff(_freq1, _sampleRate, _frameSize),
      _coeff2 = _goertzelCoeff(_freq2, _sampleRate, _frameSize);

  /// Requests microphone permission and returns whether it was granted.
  static Future<bool> requestPermission() async {
    final recorder = AudioRecorder();
    final granted = await recorder.hasPermission();
    recorder.dispose();
    return granted;
  }

  bool _active = false;

  /// Start microphone capture and begin detection. No-op if already running.
  /// Silently no-ops if microphone permission is not granted.
  Future<void> start() async {
    if (_active) return;
    _active = true;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission || !_active) {
      _active = false;
      return;
    }

    final Stream<Uint8List> stream;
    try {
      stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: 1,
          audioInterruption: AudioInterruptionMode.none,
          androidConfig: AndroidRecordConfig(manageBluetooth: false),
        ),
      );
    } catch (_) {
      _active = false;
      rethrow;
    }
    if (!_active) {
      await _recorder.stop();
      return;
    }

    _audioSub = stream.listen(_onAudioData);
  }

  /// Stop capture. Can be restarted by calling [start] again.
  Future<void> stop() async {
    _active = false;
    await _audioSub?.cancel();
    _audioSub = null;
    await _recorder.stop();
    _state = _DetectionState.idle;
    _freq1At = null;
    _buffer.clear();
  }

  void dispose() {
    stop().then((_) => _recorder.dispose());
    _controller.close();
    _buffer.clear();
  }

  void _onAudioData(Uint8List data) {
    _buffer.addAll(data);
    while (_buffer.length >= _frameSize * 2) {
      _processFrame();
    }
  }

  void _processFrame() {
    final frameBytes = Uint8List.fromList(_buffer.sublist(0, _frameSize * 2));
    _buffer.removeRange(0, _frameSize * 2);

    final bd = frameBytes.buffer.asByteData();

    double s1a = 0, s1b = 0;
    double s2a = 0, s2b = 0;

    for (var i = 0; i < _frameSize * 2; i += 2) {
      final sample = bd.getInt16(i, Endian.little) / 32768.0;

      final n1 = sample + _coeff1 * s1a - s1b;
      s1b = s1a;
      s1a = n1;

      final n2 = sample + _coeff2 * s2a - s2b;
      s2b = s2a;
      s2a = n2;
    }

    final power1 = s1a * s1a + s1b * s1b - _coeff1 * s1a * s1b;
    final power2 = s2a * s2a + s2b * s2b - _coeff2 * s2a * s2b;

    _advance(power1, power2);
  }

  void _advance(double power1, double power2) {
    switch (_state) {
      case _DetectionState.idle:
        if (power1 > _threshold) {
          _state = _DetectionState.freq1Heard;
          _freq1At = DateTime.now();
        }
      case _DetectionState.freq1Heard:
        if (DateTime.now().difference(_freq1At!) > _freq2Timeout) {
          _state = _DetectionState.idle;
          _freq1At = null;
        } else if (power2 > _threshold && power1 < _threshold) {
          // Require freq1 to have fallen silent before confirming freq2.
          // Chunk-tone harmonics (e.g. 440 Hz → 880 Hz + 1320 Hz) are
          // simultaneous, so power1 stays high when power2 rises.
          // The real completion signal is sequential, so power1 drops to
          // near-zero before the 1320 Hz tone begins.
          _state = _DetectionState.idle;
          _freq1At = null;
          if (!_controller.isClosed) _controller.add(null);
        }
    }
  }

  static double _goertzelCoeff(double freq, int sampleRate, int frameSize) {
    final k = (frameSize * freq / sampleRate).round();
    final omega = 2 * math.pi * k / frameSize;
    return 2 * math.cos(omega);
  }
}

enum _DetectionState { idle, freq1Heard }
