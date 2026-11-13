import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'types.dart';

/// What [Ffmpeg.probe] reads, with what [Ffmpeg.compress] also needs.
typedef FfprobeResult = ({VideoInfo info, double? frameRate});

/// Video compression with the `ffmpeg` and `ffprobe` commands, for Linux.
///
/// In the Flatpak they come with the runtime, whose `codecs-extra`
/// extension adds the H.264 encoder; elsewhere they're the system's. They
/// run as separate programs, so nothing of FFmpeg is bundled or linked.
class Ffmpeg {
  const Ffmpeg._();

  /// Null unless `ffprobe` runs and `ffmpeg` has the x264 and AAC encoders.
  /// Builds without x264, like Fedora's default one, may list OpenH264, but
  /// that's often only a stub library, and they can't read HEVC either.
  static Future<Ffmpeg?> find() async {
    try {
      final probe = await Process.run('ffprobe', ['-version']);
      final ffmpeg = await Process.run('ffmpeg', ['-hide_banner', '-encoders']);
      if (probe.exitCode != 0 || ffmpeg.exitCode != 0) return null;
      final names = encoderNames(ffmpeg.stdout as String);
      if (!names.containsAll(['libx264', 'aac'])) return null;
      return const Ffmpeg._();
    } on ProcessException {
      return null;
    }
  }

  Future<FfprobeResult> probe(String path) async {
    final result = await Process.run('ffprobe', [
      '-v',
      'error',
      '-print_format',
      'json',
      '-show_streams',
      '-show_format',
      path,
    ]);
    if (result.exitCode != 0) {
      throw PlatformException(code: 'failed', message: '${result.stderr}');
    }
    return parseFfprobe(jsonDecode(result.stdout as String) as Map);
  }

  /// Encodes [input] into a new MP4 at [output]. Completing [cancel] stops
  /// it, deletes [output] and throws [VideoCompressionCancelled].
  Future<void> compress({
    required String input,
    required String output,
    required VideoEncodeSettings settings,
    void Function(double progress)? onProgress,
    Future<void>? cancel,
  }) async {
    final source = await probe(input);
    final process = await Process.start(
      'ffmpeg',
      ffmpegArguments(
        input: input,
        output: output,
        settings: settings,
        source: source,
      ),
    );
    var cancelled = false;
    unawaited(
      cancel?.then((_) {
        cancelled = true;
        process.kill();
      }),
    );
    // Only the end of ffmpeg's log is kept, to explain a failure.
    final log = <String>[];
    final stderrDone = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach((line) {
          log.add(line);
          if (log.length > 20) log.removeAt(0);
        });
    final durationUs = source.info.duration.inMicroseconds;
    await process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach((line) {
          // -progress writes "key=value" lines; out_time_us is how far the
          // output has got.
          if (!line.startsWith('out_time_us=') || durationUs <= 0) return;
          final us = int.tryParse(line.substring('out_time_us='.length));
          if (us != null) onProgress?.call((us / durationUs).clamp(0, 1));
        });
    await stderrDone;
    final exitCode = await process.exitCode;
    if (cancelled || exitCode != 0) {
      final file = File(output);
      if (await file.exists()) await file.delete();
      if (cancelled) throw const VideoCompressionCancelled();
      throw PlatformException(code: 'failed', message: log.join('\n'));
    }
    onProgress?.call(1);
  }
}

/// The encoder names in `ffmpeg -encoders` output, whose lines are flags,
/// name and description.
@visibleForTesting
Set<String> encoderNames(String output) => {
  for (final line in const LineSplitter().convert(output))
    if (line.trim().split(RegExp(r'\s+')) case [_, final name, ...]) name,
};

/// Reads `ffprobe -print_format json -show_streams -show_format` output.
@visibleForTesting
FfprobeResult parseFfprobe(Map json) {
  final streams = (json['streams'] as List? ?? []).cast<Map>();
  final video = streams.firstWhere(
    (s) =>
        s['codec_type'] == 'video' &&
        (s['disposition'] as Map?)?['attached_pic'] != 1,
    orElse: () =>
        throw PlatformException(code: 'failed', message: 'No video stream'),
  );
  final width = video['width'] as int;
  final height = video['height'] as int;
  final rotated = _rotation(video) % 180 != 0;
  final seconds = double.tryParse('${(json['format'] as Map?)?['duration']}');
  return (
    info: VideoInfo(
      duration: Duration(microseconds: ((seconds ?? 0) * 1e6).round()),
      width: rotated ? height : width,
      height: rotated ? width : height,
      hasAudio: streams.any((s) => s['codec_type'] == 'audio'),
    ),
    frameRate: _rate('${video['avg_frame_rate']}'),
  );
}

/// Phones store portrait videos as landscape frames plus a rotation, in
/// the display matrix or, from older muxers, a tag.
int _rotation(Map stream) {
  for (final data in (stream['side_data_list'] as List? ?? []).cast<Map>()) {
    if (data['rotation'] case final num rotation) return rotation.round();
  }
  return int.tryParse('${(stream['tags'] as Map?)?['rotate']}') ?? 0;
}

/// A rate like "30000/1001", or null if unknown ("0/0").
double? _rate(String rate) {
  final parts = rate.split('/');
  final numerator = double.tryParse(parts.first);
  final denominator = parts.length > 1 ? double.tryParse(parts[1]) : 1.0;
  if (numerator == null || denominator == null || denominator == 0) {
    return null;
  }
  final value = numerator / denominator;
  return value > 0 ? value : null;
}

/// The ffmpeg command line for [settings], like the other platforms: H.264
/// in 8-bit 4:2:0 for players everywhere, AAC, MP4. ffmpeg applies the
/// rotation before the filters, so they see the size as displayed.
@visibleForTesting
List<String> ffmpegArguments({
  required String input,
  required String output,
  required VideoEncodeSettings settings,
  required FfprobeResult source,
}) {
  final info = source.info;
  final scale = min(1.0, settings.shortSide / max(1, info.shortSide));
  final filters = [
    'scale=${_even(info.width * scale)}:${_even(info.height * scale)}',
    // Only drops frames: below the cap, fps would repeat them.
    if (source.frameRate case final rate? when rate > settings.frameRate + 0.5)
      'fps=${settings.frameRate}',
    'format=yuv420p',
  ];
  return [
    '-hide_banner',
    '-nostdin',
    '-nostats',
    '-y',
    '-i',
    input,
    '-map',
    '0:v:0',
    '-map',
    '0:a:0?',
    '-vf',
    filters.join(','),
    '-c:v',
    'libx264',
    '-b:v',
    '${settings.videoBitrate}',
    '-maxrate',
    '${settings.videoBitrate * 3 ~/ 2}',
    '-bufsize',
    '${settings.videoBitrate * 2}',
    '-preset',
    'veryfast',
    '-profile:v',
    'high',
    '-c:a',
    'aac',
    '-b:a',
    '${settings.audioBitrate}',
    '-ac',
    '${settings.audioChannels}',
    '-progress',
    'pipe:1',
    output,
  ];
}

/// Encoders want even dimensions.
int _even(double value) => max(2, (value / 2).round() * 2);
