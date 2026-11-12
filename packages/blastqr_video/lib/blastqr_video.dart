import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// What [BlastqrVideo.probe] reads from a video without decoding it.
class VideoInfo {
  const VideoInfo({
    required this.duration,
    required this.width,
    required this.height,
    required this.hasAudio,
  });

  final Duration duration;

  /// The size as displayed, with rotation applied.
  final int width;
  final int height;

  final bool hasAudio;

  int get shortSide => min(width, height);
}

/// How [BlastqrVideo.compress] encodes: H.264 and AAC in an MP4.
class VideoEncodeSettings {
  const VideoEncodeSettings({
    required this.videoBitrate,
    required this.audioBitrate,
    required this.shortSide,
    required this.frameRate,
    this.audioChannels = 2,
  });

  /// Bits per second.
  final int videoBitrate;

  /// Bits per second.
  final int audioBitrate;

  /// 1 mixes the audio down to mono, which needs half the bitrate.
  final int audioChannels;

  /// The output's shorter side in pixels. The aspect ratio is kept.
  final int shortSide;

  /// Frames beyond this rate are dropped.
  final int frameRate;

  Map<String, Object> toMap() => {
    'videoBitrate': videoBitrate,
    'audioBitrate': audioBitrate,
    'shortSide': shortSide,
    'frameRate': frameRate,
    'audioChannels': audioChannels,
  };

  @override
  String toString() =>
      '${shortSide}p ${frameRate}fps, video ${videoBitrate ~/ 1000} kbps, '
      'audio ${audioBitrate ~/ 1000} kbps${audioChannels == 1 ? ' mono' : ''}';
}

class VideoCompressionCancelled implements Exception {
  const VideoCompressionCancelled();
}

class BlastqrVideo {
  const BlastqrVideo._();

  static const _channel = MethodChannel('blastqr_video');
  static final _progressCallbacks = <int, void Function(double)>{};
  static var _nextId = 0;
  static var _listening = false;

  static bool get isSupported =>
      !kIsWeb && (Platform.isIOS || Platform.isAndroid || Platform.isMacOS);

  static Future<VideoInfo> probe(String path) async {
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
