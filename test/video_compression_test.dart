import 'package:blast_qr/features/send/helpers/video_compression.dart';
import 'package:blast_qr/model/video_quality.dart';
import 'package:blastqr_video/blastqr_video.dart';
import 'package:flutter_test/flutter_test.dart';

const _mb = 1000000;

VideoInfo _video(
  Duration duration, {
  int width = 1920,
  int height = 1080,
  bool hasAudio = true,
}) => VideoInfo(
  duration: duration,
  width: width,
  height: height,
  hasAudio: hasAudio,
);

/// [sourceBytes] for a video of [duration] at [mbps].
int _bytesAt(double mbps, Duration duration) =>
    (mbps * _mb / 8 * duration.inSeconds).round();

VideoEncodeSettings? _settingsFor(
  VideoInfo info, {
  required int sourceBytes,
  VideoQuality quality = VideoQuality.low,
}) => encodeSettingsFor(info, sourceBytes: sourceBytes, quality: quality);

void main() {
  group('encodeSettingsFor', () {
    const tenSeconds = Duration(seconds: 10);
    const minute = Duration(minutes: 1);

    test('a phone clip goes to 540p at about 1 Mbps', () {
      final settings = _settingsFor(_video(tenSeconds), sourceBytes: 11 * _mb)!;

      expect(settings.videoBitrate, 1000000);
      expect(settings.audioBitrate, 64000);
      expect(settings.shortSide, 540);
      expect(settings.frameRate, 30);
    });

    test('never goes above 70% of the original bitrate', () {
      final settings = _settingsFor(
        _video(minute),
        sourceBytes: _bytesAt(1.2, minute),
      )!;

      // 1.2 Mbps * 0.7, minus 64 kbps of audio.
      expect(settings.videoBitrate, 776000);
    });

    test('compresses a modest bitrate to 70% of it', () {
      final settings = _settingsFor(
        _video(minute),
        sourceBytes: _bytesAt(0.8, minute),
      )!;

      expect(settings.videoBitrate, 496000);
    });

    test('skips low bitrates, where the minimum bitrate saves too little', () {
      expect(
        _settingsFor(_video(minute), sourceBytes: _bytesAt(0.25, minute)),
        isNull,
      );
    });

    test('keeps long videos under the maximum size', () {
      const duration = Duration(minutes: 3);
      final settings = _settingsFor(
        _video(duration, width: 3840, height: 2160),
        sourceBytes: _bytesAt(20, duration),
      )!;

      final bytes =
          (settings.videoBitrate + settings.audioBitrate) *
          duration.inSeconds /
          8;
      expect(bytes, lessThan(maxVideoBytes));
      expect(settings.shortSide, 360);
    });

    test('keeps a minimum bitrate for very long videos', () {
      const duration = Duration(hours: 1);
      final settings = _settingsFor(
        _video(duration),
        sourceBytes: _bytesAt(10, duration),
      )!;

      expect(settings.videoBitrate, 150000);
      expect(settings.shortSide, 240);
    });

    test('lowest goes to 360p at about 400 kbps', () {
      final settings = _settingsFor(
        _video(tenSeconds),
        sourceBytes: 11 * _mb,
        quality: VideoQuality.lowest,
      )!;

      expect(settings.videoBitrate, 400000);
      expect(settings.shortSide, 360);
    });

    test('potato goes to 240p at 15 fps with mono audio', () {
      final settings = _settingsFor(
        _video(tenSeconds),
        sourceBytes: 11 * _mb,
        quality: VideoQuality.potato,
      )!;

      expect(settings.videoBitrate, 200000);
      expect(settings.shortSide, 240);
      expect(settings.frameRate, 15);
      expect(settings.audioBitrate, 32000);
      expect(settings.audioChannels, 1);
    });

    test('original sends videos as they are', () {
      expect(
        _settingsFor(
          _video(tenSeconds),
          sourceBytes: 11 * _mb,
          quality: VideoQuality.original,
        ),
        isNull,
      );
    });

    test('never scales up', () {
      final settings = _settingsFor(
        _video(tenSeconds, width: 640, height: 480),
        sourceBytes: 11 * _mb,
      )!;

      expect(settings.shortSide, 480);
    });

    test('uses the short side of portrait videos', () {
      final settings = _settingsFor(
        _video(tenSeconds, width: 1080, height: 1920),
        sourceBytes: 11 * _mb,
      )!;

      expect(settings.shortSide, 540);
    });

    test('a video without audio keeps the same video bitrate', () {
      final settings = _settingsFor(
        _video(tenSeconds, hasAudio: false),
        sourceBytes: 11 * _mb,
      )!;

      expect(settings.videoBitrate, 1000000);
    });
  });

  test('estimatedVideoBytes counts audio only if there is some', () {
    const settings = VideoEncodeSettings(
      videoBitrate: 1000000,
      audioBitrate: 64000,
      shortSide: 540,
      frameRate: 30,
    );

    expect(
      estimatedVideoBytes(_video(const Duration(seconds: 8)), settings),
      1064000,
    );
    expect(
      estimatedVideoBytes(
        _video(const Duration(seconds: 8), hasAudio: false),
        settings,
      ),
      1000000,
    );
  });
}
