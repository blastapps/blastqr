import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'src/ffmpeg.dart';
import 'src/types.dart';

export 'src/types.dart';

/// Re-encodes videos with the platform's encoder: AVFoundation on iOS and
/// macOS, Media3 on Android, and ffmpeg on Linux when it's installed.
class BlastqrVideo {
  const BlastqrVideo._();

  static const _channel = MethodChannel('blastqr_video');
  static final _progressCallbacks = <int, void Function(double)>{};
  static var _nextId = 0;
  static var _listening = false;

  static Future<bool>? _supported;
  static Ffmpeg? _ffmpeg;

  /// Whether videos can be compressed here. On Linux that needs ffmpeg with
  /// an H.264 encoder, which is checked once.
  static Future<bool> isSupported() => _supported ??= _findSupport();

  static Future<bool> _findSupport() async {
    if (kIsWeb) return false;
    if (Platform.isIOS || Platform.isAndroid || Platform.isMacOS) return true;
    if (Platform.isLinux) return (_ffmpeg = await Ffmpeg.find()) != null;
    return false;
  }

  /// ffmpeg on Linux, null where the platform's own encoder is used.
  static Future<Ffmpeg?> _ffmpegIfLinux() async {
    if (kIsWeb || !Platform.isLinux) return null;
    if (!await isSupported()) {
      throw PlatformException(code: 'unsupported', message: 'No ffmpeg');
    }
    return _ffmpeg;
  }

  static Future<VideoInfo> probe(String path) async {
    if (await _ffmpegIfLinux() case final ffmpeg?) {
      return (await ffmpeg.probe(path)).info;
    }
    final info = await _channel.invokeMapMethod<String, Object?>('probe', path);
    if (info == null) throw PlatformException(code: 'failed');
    return VideoInfo(
      duration: Duration(milliseconds: (info['durationMs'] as num).round()),
      width: info['width'] as int,
      height: info['height'] as int,
      hasAudio: info['hasAudio'] as bool,
    );
  }

  /// Encodes [input] into a new MP4 at [output]. [onProgress] gets values
  /// from 0 to 1. Completing [cancel] stops the encoding, deletes [output]
  /// and throws [VideoCompressionCancelled].
  static Future<void> compress({
    required String input,
    required String output,
    required VideoEncodeSettings settings,
    void Function(double progress)? onProgress,
    Future<void>? cancel,
  }) async {
    if (await _ffmpegIfLinux() case final ffmpeg?) {
      return ffmpeg.compress(
        input: input,
        output: output,
        settings: settings,
        onProgress: onProgress,
        cancel: cancel,
      );
    }
    _listen();
    final id = _nextId++;
    if (onProgress != null) _progressCallbacks[id] = onProgress;
    unawaited(cancel?.then((_) => _channel.invokeMethod<void>('cancel', id)));
    try {
      await _channel.invokeMethod<void>('compress', {
        'id': id,
        'input': input,
        'output': output,
        ...settings.toMap(),
      });
    } on PlatformException catch (e) {
      if (e.code == 'cancelled') throw const VideoCompressionCancelled();
      rethrow;
    } finally {
      _progressCallbacks.remove(id);
    }
  }

  static void _listen() {
    if (_listening) return;
    _listening = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'progress') return;
      final args = call.arguments as Map;
      _progressCallbacks[args['id']]?.call(
        (args['progress'] as num).toDouble(),
      );
    });
  }
}
