import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:record/record.dart';

/// Listens to the microphone and detects the acoustic acknowledgement that
/// the receiving device plays when a blastQR transfer completes.
///
/// The receiver plays C6, E6, G6, each with a strong octave overtone. Only the
/// overtones (C7, E7, G7) are detected: the chunk tones' harmonics reach up to
/// about 1.8 kHz, so the fundamentals could be faked by them.
///
/// Uses the Goertzel algorithm for efficient single-frequency power estimation.
/// A note counts as present when it stands well above the frequencies around
/// it, so broadband noise raises both and doesn't trigger. Each note must be
/// present in two windows in a row, after the previous note has gone, within
/// [_timeoutMs] of it.
class AcousticAckListener {
  static const int _sampleRate = 16000;
  static const int _windowSize = 1600; // 100 ms
  static const int _hopSize = 800; // 50 ms

  /// Twice the notes in [SoundFeedbackService._buildCompletionWav].
  static const _freqs = [2093.0, 2637.0, 3136.0];
  static const int _timeoutMs = 500;

  /// Minimum raw Goertzel power to count a note as present.
  static const double _minPower = 0.2;

  /// How much stronger a note must be than the average of its neighbours.
  static const double _minRatio = 10.0;

  /// Neighbour offsets in Hz; multiples of the 10 Hz bin spacing.
  static const _neighbourOffsets = [-100.0, -50.0, 50.0, 100.0];

  final _notes = [for (final f in _freqs) _Note(f)];

  /// Number of notes heard so far.
  int _heard = 0;
  int _lastHeardMs = 0;

  final _controller = StreamController<void>.broadcast();

  /// Fires each time a completion sequence is detected.
  Stream<void> get onDetected => _controller.stream;

  final _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _audioSub;

  final _buffer = <int>[];

  /// Samples processed since start, used as the clock for timeouts.
  int _samplesProcessed = 0;

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
    _resetNotes();
    _samplesProcessed = 0;
    _buffer.clear();
  }

  void dispose() {
    stop().then((_) => _recorder.dispose());
    _controller.close();
    _buffer.clear();
  }

  void _onAudioData(Uint8List data) {
    _buffer.addAll(data);
    while (_buffer.length >= _windowSize * 2) {
      _processWindow();
      _buffer.removeRange(0, _hopSize * 2);
      _samplesProcessed += _hopSize;
    }
  }

  void _processWindow() {
    final bytes = Uint8List.fromList(_buffer.sublist(0, _windowSize * 2));
    final bd = bytes.buffer.asByteData();
    final samples = Float64List(_windowSize);
    for (var i = 0; i < _windowSize; i++) {
      samples[i] = bd.getInt16(i * 2, Endian.little) / 32768.0;
    }

    for (final note in _notes) {
      note.update(samples);
    }
    final nowMs = _samplesProcessed * 1000 ~/ _sampleRate;
    if (_advance(nowMs) && !_controller.isClosed) {
      _resetNotes();
      _controller.add(null);
    }
  }

  /// Returns true when the last note is heard.
  bool _advance(int nowMs) {
    if (_heard > 0 && nowMs - _lastHeardMs > _timeoutMs) _heard = 0;

    final ready = _heard == 0
        ? _notes[0].confirmed
        : _notes[_heard].confirmed && !_notes[_heard - 1].present;
    if (!ready) return false;

    _heard++;
    _lastHeardMs = nowMs;
    return _heard == _notes.length;
  }

  void _resetNotes() {
    _heard = 0;
    for (final n in _notes) {
      n.reset();
    }
  }
}

double _goertzel(Float64List samples, double coeff) {
  double s1 = 0, s2 = 0;
  for (final x in samples) {
    final s0 = x + coeff * s1 - s2;
    s2 = s1;
    s1 = s0;
  }
  return s1 * s1 + s2 * s2 - coeff * s1 * s2;
}

double _coeff(double freq) =>
    2 * math.cos(2 * math.pi * freq / AcousticAckListener._sampleRate);

class _Note {
  _Note(double freq)
    : _coeff0 = _coeff(freq),
      _neighbourCoeffs = [
        for (final o in AcousticAckListener._neighbourOffsets) _coeff(freq + o),
      ];

  final double _coeff0;
  final List<double> _neighbourCoeffs;

  /// Present in the latest window.
  bool present = false;

  /// Present in the latest two windows.
  bool confirmed = false;

  void update(Float64List samples) {
    final power = _goertzel(samples, _coeff0);
    var neighbours = 0.0;
    for (final c in _neighbourCoeffs) {
      neighbours += _goertzel(samples, c);
    }
    neighbours /= _neighbourCoeffs.length;
    final now =
        power > AcousticAckListener._minPower &&
        power > AcousticAckListener._minRatio * neighbours;
    confirmed = present && now;
    present = now;
  }

  void reset() => present = confirmed = false;
}
