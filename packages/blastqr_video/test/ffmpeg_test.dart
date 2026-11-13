import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:blastqr_video/blastqr_video.dart';
import 'package:blastqr_video/src/ffmpeg.dart';
import 'package:flutter_test/flutter_test.dart';

const _potato = VideoEncodeSettings(
  videoBitrate: 200000,
  audioBitrate: 32000,
  shortSide: 240,
  frameRate: 15,
  audioChannels: 1,
);

void main() {
  group('encoderNames', () {
    test('reads the name column', () {
      const output = '''
Encoders:
 V..... = Video
 ------
 V....D libx264              libx264 H.264 / AVC
 A....D aac                  AAC (Advanced Audio Coding)
''';

      expect(encoderNames(output), containsAll(['libx264', 'aac']));
    });
  });

  group('parseFfprobe', () {
    test('a portrait phone video, stored landscape with a rotation', () {
      final result = parseFfprobe({
        'streams': [
          {
            'codec_type': 'video',
            'width': 1920,
            'height': 1080,
            'avg_frame_rate': '30000/1001',
            'side_data_list': [
              {'side_data_type': 'Display Matrix', 'rotation': -90},
            ],
          },
          {'codec_type': 'audio'},
        ],
        'format': {'duration': '12.500000'},
      });

      expect(result.info.width, 1080);
      expect(result.info.height, 1920);
      expect(result.info.hasAudio, isTrue);
      expect(result.info.duration, const Duration(milliseconds: 12500));
      expect(result.frameRate, closeTo(29.97, 0.01));
    });

    test('skips cover art and reads the old rotate tag', () {
      final result = parseFfprobe({
        'streams': [
          {
            'codec_type': 'video',
            'width': 300,
            'height': 300,
            'disposition': {'attached_pic': 1},
          },
          {
            'codec_type': 'video',
            'width': 1280,
            'height': 720,
            'avg_frame_rate': '0/0',
            'tags': {'rotate': '90'},
          },
        ],
        'format': {'duration': '1.0'},
      });

      expect(result.info.width, 720);
      expect(result.info.height, 1280);
      expect(result.info.hasAudio, isFalse);
      expect(result.frameRate, isNull);
    });
  });

  group('ffmpegArguments', () {
    List<String> arguments({double? frameRate}) => ffmpegArguments(
      input: 'in.mov',
      output: 'out.mp4',
      settings: _potato,
      source: (
        info: const VideoInfo(
          duration: Duration(seconds: 10),
          width: 1080,
          height: 1920,
          hasAudio: true,
        ),
        frameRate: frameRate,
      ),
    );

    String filters(List<String> args) => args[args.indexOf('-vf') + 1];

    test('scales the short side and caps the frame rate', () {
      final args = arguments(frameRate: 60);

      expect(filters(args), 'scale=240:426,fps=15,format=yuv420p');
      expect(args, containsAllInOrder(['-c:v', 'libx264', '-b:v', '200000']));
      expect(args, containsAllInOrder(['-b:a', '32000', '-ac', '1']));
      expect(args.last, 'out.mp4');
    });

    test('never adds frames to a slower video', () {
      expect(filters(arguments(frameRate: 12)), isNot(contains('fps=')));
      expect(filters(arguments()), isNot(contains('fps=')));
    });
  });

  group('with ffmpeg installed', () {
    late Directory temp;
    late String input;
    Ffmpeg? ffmpeg;

    setUpAll(() async => ffmpeg = await Ffmpeg.find());

    setUp(() async {
      temp = Directory.systemTemp.createTempSync('ffmpeg_test');
      input = '${temp.path}/input.mp4';
      // A 60 fps 1080p clip with stereo sound.
      final result = await Process.run('ffmpeg', [
        '-loglevel', 'error', //
        '-f', 'lavfi', '-i', 'testsrc2=size=1920x1080:rate=60:duration=3',
        '-f', 'lavfi', '-i', 'sine=frequency=440:duration=3',
        '-ac', '2', '-c:v', 'libx264', '-c:a', 'aac', input,
      ]);
      expect(result.exitCode, 0, reason: '${result.stderr}');
    });

    tearDown(() => temp.deleteSync(recursive: true));

    Future<Map> streams(String path) async {
      final result = await Process.run('ffprobe', [
        '-v', 'error', '-count_frames', //
        '-print_format', 'json', '-show_streams', path,
      ]);
      return jsonDecode(result.stdout as String) as Map;
    }

    test('compresses as asked, reporting progress', () async {
      final output = '${temp.path}/output.mp4';
      final progress = <double>[];

      await ffmpeg!.compress(
        input: input,
        output: output,
        settings: _potato,
        onProgress: progress.add,
      );

      final [video, audio] = (await streams(output))['streams'] as List;
      expect(video['height'], 240);
      expect(int.parse(video['nb_read_frames'] as String), 45);
      expect(audio['channels'], 1);
      expect(progress.last, 1);
      expect(File(output).lengthSync(), lessThan(File(input).lengthSync()));
    });

    test('cancelling stops it and deletes the output', () async {
      final output = '${temp.path}/output.mp4';
      final cancel = Completer<void>();

      final compressing = ffmpeg!.compress(
        input: input,
        output: output,
        settings: _potato,
        cancel: cancel.future,
      );
      cancel.complete();

      await expectLater(compressing, throwsA(isA<VideoCompressionCancelled>()));
      expect(File(output).existsSync(), isFalse);
    });
  }, skip: !_hasFfmpeg());
}

/// Like [Ffmpeg.find], but synchronous, for deciding what to skip.
bool _hasFfmpeg() {
  try {
    final probe = Process.runSync('ffprobe', ['-version']);
    final ffmpeg = Process.runSync('ffmpeg', ['-hide_banner', '-encoders']);
    final names = encoderNames(ffmpeg.stdout as String);
    return probe.exitCode == 0 && names.containsAll(['libx264', 'aac']);
  } on ProcessException {
    return false;
  }
}
