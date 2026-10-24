import 'package:blast_qr/features/send/widgets/raptorq_qr_streaming_widget.dart';
import 'package:flutter_test/flutter_test.dart';

Duration _ms(num ms) => Duration(microseconds: (ms * 1000).round());

void main() {
  late RaptorQrStreamingWidgetController controller;

  setUp(() {
    controller = RaptorQrStreamingWidgetController()
      ..setLength(1000)
      ..start(20); // 50 ms per frame
  });

  List<int> cells(int count) => [
    for (var i = 0; i < count; i++) controller.framesAdvanced(i, count),
  ];

  test('single code advances once per frame interval', () {
    controller.tick(_ms(0));
    expect(controller.currentChunkIndex, 0);
    controller.tick(_ms(49));
    expect(controller.currentChunkIndex, 0);
    controller.tick(_ms(50));
    expect(controller.currentChunkIndex, 1);
    controller.tick(_ms(1000));
    expect(controller.currentChunkIndex, 20);
  });

  test('codes in a grid change at staggered times, never together', () {
    // 4 codes at 20 fps: code j changes at 50·k + 12.5·j ms.
    controller.tick(_ms(50));
    expect(cells(4), [1, 0, 0, 0]);
    controller.tick(_ms(62.5));
    expect(cells(4), [1, 1, 0, 0]);
    controller.tick(_ms(75));
    expect(cells(4), [1, 1, 1, 0]);
    controller.tick(_ms(87.5));
    expect(cells(4), [1, 1, 1, 1]);
    controller.tick(_ms(100));
    expect(cells(4), [2, 1, 1, 1]);
  });

  test('at most one code changes in any instant', () {
    var previous = cells(6);
    for (var t = 0.0; t < 2000; t += 0.5) {
      controller.tick(_ms(t));
      final current = cells(6);
      var changed = 0;
      for (var i = 0; i < 6; i++) {
        if (current[i] != previous[i]) changed++;
      }
      expect(changed, lessThanOrEqualTo(1), reason: 'at $t ms');
      previous = current;
    }
  });

  test('each code still changes at the playback fps', () {
    controller.tick(_ms(10000));
    for (final advanced in cells(6)) {
      expect(advanced, inInclusiveRange(199, 200));
    }
  });

  test('changing fps keeps the frames already played', () {
    controller.tick(_ms(1000)); // 20 frames at 20 fps
    controller.setFps(10);
    controller.tick(_ms(1000));
    expect(controller.currentChunkIndex, 20);
    controller.tick(_ms(2000)); // +10 frames at 10 fps
    expect(controller.currentChunkIndex, 30);
  });

  test('stopAnimation freezes playback', () {
    controller.tick(_ms(500));
    controller.stopAnimation();
    controller.tick(_ms(5000));
    expect(controller.currentChunkIndex, 10);
  });
}
