import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_soloud/flutter_soloud.dart';

/// Plays two simultaneous sine-wave tones on each chunk event:
///   - Progress tone (110-440 Hz, low register): rises as transfer progresses 0->1
///   - Speed tone (200-500 Hz, mid register): rises with current kB/s up to 176 kB/s
/// Both tones use additive synthesis (fundamental + 2nd + 3rd harmonics) for a warmer sound.
/// Playback is handled by flutter_soloud (C++ audio thread) for low latency and no crackling.
class SoundFeedbackService {
  static const int _sampleRate = 22050;
  static const int _stepCount = 10;

  // A minor pentatonic (A, C, D, E, G) — any two notes from this scale
  // will always sound consonant together.
  // Progress: A2 → G4 (low register)
  static const _progressFreqs = [
    110.00, 130.81, 146.83, 164.81, 196.00, // A2 C3 D3 E3 G3
    220.00, 261.63, 293.66, 329.63, 392.00, // A3 C4 D4 E4 G4
  ];
  // Speed: E3 → D5 (same scale, shifted up a fifth for distinction)
  static const _speedFreqs = [
    164.81, 196.00, 220.00, 261.63, 293.66, // E3 G3 A3 C4 D4
    329.63, 392.00, 440.00, 523.25, 587.33, // E4 G4 A4 C5 D5
  ];
  static const double _speedMaxKBs = 176.0;

  static const _chunkToneInterval = Duration(milliseconds: 50);
  DateTime _lastChunkToneTime = DateTime.fromMillisecondsSinceEpoch(0);

  final _soloud = SoLoud.instance;

  List<AudioSource>? _progressSources;
  List<AudioSource>? _speedSources;
  AudioSource? _completionSource;
  AudioSource? _qrSource;

  SoundFeedbackService() {
    _init();
  }

  Future<void> _init() async {
    if (!_soloud.isInitialized) {
      await _soloud.init();
    }

    _progressSources = await Future.wait(
      List.generate(_stepCount, (i) async {
        return _soloud.loadMem(
          'bqr_progress_$i',
          _buildWav(_progressFreqs[i], durationMs: 60),
        );
      }),
    );

    _speedSources = await Future.wait(
      List.generate(_stepCount, (i) async {
        return _soloud.loadMem(
          'bqr_speed_$i',
          _buildWav(_speedFreqs[i], durationMs: 60),
        );
      }),
    );

    _completionSource = await _soloud.loadMem(
      'bqr_complete',
      _buildCompletionWav(),
    );

    _qrSource = await _soloud.loadMem(
      'bqr_qr',
      _buildWav(220.0, durationMs: 100),
    );
  }

  /// Play the two chunk-received tones simultaneously.
  /// [progress] in 0.0-1.0, [speedKBs] is current transfer speed in kB/s.
  /// Throttled to [_chunkToneInterval].
  void playChunkReceived(double progress, double speedKBs) {
    final progressSources = _progressSources;
    final speedSources = _speedSources;
    if (progressSources == null || speedSources == null) return;
    final now = DateTime.now();
    if (now.difference(_lastChunkToneTime) < _chunkToneInterval) return;
    _lastChunkToneTime = now;

    final progressIndex = (progress.clamp(0.0, 1.0) * (_stepCount - 1)).round();
    _soloud.play(progressSources[progressIndex]);

    final speedIndex =
        ((speedKBs / _speedMaxKBs).clamp(0.0, 1.0) * (_stepCount - 1)).round();
    _soloud.play(speedSources[speedIndex]);
  }

  /// Play the transfer-complete tone.
  void playTransferComplete() {
    final source = _completionSource;
    if (source == null) return;
    _lastChunkToneTime = DateTime.fromMillisecondsSinceEpoch(0);
    _soloud.play(source);
  }

  /// Play the regular QR code tone.
  void playQRCodeResult() {
    final source = _qrSource;
    if (source == null) return;
    _soloud.play(source);
  }

  void dispose() {
    _soloud.disposeAllSources().then((_) => _soloud.deinit());
  }

  // ---------------------------------------------------------------------------
  // WAV generation
  // ---------------------------------------------------------------------------

  /// The completion signal for acoustic acknowledgement: C6, E6, G6 at
  /// 200 ms each, chime-like. Each note has a strong octave overtone, which is
  /// what [AcousticAckListener] detects.
  static Uint8List _buildCompletionWav() {
    const notes = [1046.5, 1318.5, 1568.0];
    const noteMs = 200;
    const amplitude = 0.22; // per partial
    final samplesPerNote = _sampleRate * noteMs ~/ 1000;
    final attack = (_sampleRate * 0.008).round();
    final release = (_sampleRate * 0.030).round();
    final totalSamples = samplesPerNote * notes.length;

    final dataBytes = totalSamples * 2;
    final bytes = ByteData(44 + dataBytes);
    _writeHeader(bytes, dataBytes);
    for (var n = 0; n < notes.length; n++) {
      for (var i = 0; i < samplesPerNote; i++) {
        var envelope = math.exp(-i / (_sampleRate * 0.25));
        if (i < attack) {
          envelope *= 0.5 * (1 - math.cos(math.pi * i / attack));
        } else if (i > samplesPerNote - release) {
          envelope *=
              0.5 * (1 - math.cos(math.pi * (samplesPerNote - i) / release));
        }
        final t = 2 * math.pi * notes[n] * i / _sampleRate;
        final wave = math.sin(t) + math.sin(2 * t);
        final sample = (32767 * amplitude * envelope * wave).round().clamp(
          -32768,
          32767,
        );
        bytes.setInt16(
          44 + (n * samplesPerNote + i) * 2,
          sample,
          Endian.little,
        );
      }
    }
    return bytes.buffer.asUint8List();
  }

  static Uint8List _buildWav(double frequency, {required int durationMs}) {
    final sampleCount = (_sampleRate * durationMs / 1000).round();
    final dataBytes = sampleCount * 2;
    final bytes = ByteData(44 + dataBytes);
    _writeHeader(bytes, dataBytes);
    // Additive synthesis: fundamental + 2nd harmonic (0.3×) + 3rd harmonic (0.1×).
    // Lighter overtones = softer, flute-like tone with less buzz.
    // Sum normalised to ±1 so peak amplitude is unchanged.
    const amplitude = 32767 * 0.30;
    const norm = 1.0 + 0.3 + 0.1; // = 1.4
    for (var i = 0; i < sampleCount; i++) {
      // Longer fade (300 samples ≈ 13ms) for smoother attack and release.
      final envelope = i < 300
          ? i / 300.0
          : (i > sampleCount - 300 ? (sampleCount - i) / 300.0 : 1.0);
      final t = 2 * math.pi * frequency * i / _sampleRate;
      final wave =
          (math.sin(t) + 0.3 * math.sin(2 * t) + 0.1 * math.sin(3 * t)) / norm;
      final sample = (amplitude * envelope * wave).round().clamp(-32768, 32767);
      bytes.setInt16(44 + i * 2, sample, Endian.little);
    }
    return bytes.buffer.asUint8List();
  }

  static void _writeHeader(ByteData bytes, int dataBytes) {
    _writeAscii(bytes, 0, 'RIFF');
    bytes.setUint32(4, 36 + dataBytes, Endian.little);
    _writeAscii(bytes, 8, 'WAVE');
    _writeAscii(bytes, 12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little);
    bytes.setUint16(22, 1, Endian.little);
    bytes.setUint32(24, _sampleRate, Endian.little);
    bytes.setUint32(28, _sampleRate * 2, Endian.little);
    bytes.setUint16(32, 2, Endian.little);
    bytes.setUint16(34, 16, Endian.little);
    _writeAscii(bytes, 36, 'data');
    bytes.setUint32(40, dataBytes, Endian.little);
  }

  static void _writeAscii(ByteData data, int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(offset + i, s.codeUnitAt(i));
    }
  }
}
