import 'dart:io';
import 'dart:math';

import 'package:blast_qr/app_preferences.dart';
import 'package:blast_qr/model/file_extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blast_qr/model/video_quality.dart';
import 'package:blast_qr/temp_files.dart';
import 'package:blastqr_video/blastqr_video.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Long videos are kept to about this size, at a lower resolution if need
/// be.
const maxVideoBytes = 10000000;

const _minVideoBitrate = 150000;

/// Never more than this share of the original's bitrate.
const _maxBitrateShare = 0.7;

/// Re-encoding loses quality, so it has to save at least this share.
const _minSaving = 0.25;

/// Settings for re-encoding [info], a video of [sourceBytes]: the
/// [quality]'s bitrate, less for long videos so they stay under
/// [maxVideoBytes], and never more than 70% of the original's bitrate. Null
/// for [VideoQuality.original], or if it wouldn't save at least 25%, so the
/// original is sent.
VideoEncodeSettings? encodeSettingsFor(
  VideoInfo info, {
  required int sourceBytes,
  required VideoQuality quality,
}) {
  final qualityBitrate = quality.videoBitrate;
  if (qualityBitrate == null) return null;
  final seconds = max(info.duration.inMilliseconds / 1000, 1);
  final audio = info.hasAudio ? quality.audioBitrate : 0;
  final source = sourceBytes * 8 / seconds;
  // About 10% is left for the container and the encoder overshooting.
  final ceiling = maxVideoBytes * 8 * 0.9 / seconds;
  final video = max(
    [
      qualityBitrate.toDouble(),
      ceiling - audio,
      source * _maxBitrateShare - audio,
    ].reduce(min).floor(),
    _minVideoBitrate,
  );
  final shortSide = _shortSideFor(video);
  final settings = VideoEncodeSettings(
    videoBitrate: video,
    audioBitrate: quality.audioBitrate,
    shortSide: info.shortSide > 0 ? min(info.shortSide, shortSide) : shortSide,
    frameRate: quality.frameRate,
    audioChannels: quality.audioChannels,
  );
  if (estimatedVideoBytes(info, settings) > sourceBytes * (1 - _minSaving)) {
    return null;
  }
  return settings;
}

/// About how large [info] comes out with [settings].
int estimatedVideoBytes(VideoInfo info, VideoEncodeSettings settings) {
  final audio = info.hasAudio ? settings.audioBitrate : 0;
  return ((settings.videoBitrate + audio) *
          max(info.duration.inMilliseconds, 1000) /
          8000)
      .round();
}

/// H.264 at 30 fps.
int _shortSideFor(int videoBitrate) => switch (videoBitrate) {
  >= 600000 => 540,
  >= 300000 => 360,
  _ => 240,
};

/// Compressed videos from this session by [_cacheKey], oldest first, so
/// sending the same video again, e.g. from recents after closing the QR
/// page too early, doesn't compress it again. Like other temp files, they're
/// deleted on the next launch.
final _cache = <String, FileWrapper>{};
const _maxCached = 5;

String _cacheKey(FileWrapper file, VideoQuality quality) =>
    '${file.file.path}|${file.size}|'
    '${file.modified.microsecondsSinceEpoch}|${quality.name}';

void _remember(String key, FileWrapper video) {
  _cache[key] = video;
  while (_cache.length > _maxCached) {
    _delete(_cache.remove(_cache.keys.first)!.file.parent);
  }
}

/// Re-encodes [file] with [encodeSettingsFor] as an MP4 in a new temp file
/// with the same name, or returns the one from earlier in the session. The
/// file is kept for later sends, so callers mustn't delete it. Returns null
/// if that isn't worth it, fails or doesn't make it smaller, so the original
/// is sent instead. Throws [VideoCompressionCancelled] once [cancel]
/// completes.
Future<FileWrapper?> compressVideo(
  FileWrapper file, {
  void Function(double progress)? onProgress,
  Future<void>? cancel,
}) async {
  final quality = AppPreferences.videoQuality;
  final key = _cacheKey(file, quality);
  final cached = _cache.remove(key);
  // Temp files are also cleared when files are shared into the app.
  if (cached != null && await cached.file.exists()) {
    _cache[key] = cached;
    debugPrint('Using ${file.name} compressed earlier');
    return cached;
  }

  final directory = await (await appTempDirectory()).createTemp('video_');
  final output = '${directory.path}/${file.nameWithoutExtension}.mp4';
  FileWrapper? kept;
  try {
    final info = await BlastqrVideo.probe(file.file.path);
    final settings = encodeSettingsFor(
      info,
      sourceBytes: file.size,
      quality: quality,
    );
    if (settings == null) {
      debugPrint('Not compressing ${file.name}: already small enough');
      return null;
    }
    debugPrint('Compressing ${file.name} (${info.duration}): $settings');
    final stopwatch = Stopwatch()..start();
    await BlastqrVideo.compress(
      input: file.file.path,
      output: output,
      settings: settings,
      onProgress: onProgress,
      cancel: cancel,
    );
    final compressed = await File(output).toFileWrapper();
    debugPrint(
      'Compressed video: ${file.size} -> ${compressed.size} '
      'in ${stopwatch.elapsed}',
    );
    if (compressed.size < file.size) {
      _remember(key, compressed);
      return kept = compressed;
    }
  } on PlatformException catch (e) {
    debugPrint('Video compression failed, sending the original: $e');
  } finally {
    if (kept == null) await _delete(directory);
  }
  return null;
}

Future<void> _delete(Directory directory) async {
  try {
    await directory.delete(recursive: true);
  } on FileSystemException catch (_) {}
}
