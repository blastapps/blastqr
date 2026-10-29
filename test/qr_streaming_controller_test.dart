import 'package:blast_qr/features/send/widgets/raptorq_qr_streaming_widget.dart';
import 'package:flutter_test/flutter_test.dart';

Duration _ms(num ms) => Duration(microseconds: (ms * 1000).round());

void main() {
  late RaptorQrStreamingWidgetController controller;

  setUp(() {
    controller = RaptorQrStreamingWidgetController()..start(20); // 50 ms/frame
  });

  test('advances once per frame interval', () {
    controller.tick(_ms(0));
    expect(controller.framesAdvanced, 0);
    controller.tick(_ms(49));
    expect(controller.framesAdvanced, 0);
    controller.tick(_ms(50));
    expect(controller.framesAdvanced, 1);
    controller.tick(_ms(1000));
    expect(controller.framesAdvanced, 20);
  });

  test('notifies once per frame', () {
    var notifications = 0;
    controller.addListener(() => notifications++);
    for (var t = 0.0; t < 1000; t += 1000 / 120) {
      controller.tick(_ms(t));
    }
    expect(notifications, 20);
  });

  test('changing fps keeps the frames already played', () {
    controller.tick(_ms(1000)); // 20 frames at 20 fps
    controller.setFps(10);
    controller.tick(_ms(1000));
    expect(controller.framesAdvanced, 20);
    controller.tick(_ms(2000)); // +10 frames at 10 fps
    expect(controller.framesAdvanced, 30);
  });

  test('stopAnimation freezes playback', () {
    controller.tick(_ms(500));
    controller.stopAnimation();
    controller.tick(_ms(5000));
    expect(controller.framesAdvanced, 10);
  });
}
