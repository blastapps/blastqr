import 'dart:math';

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
