import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_zxing/flutter_zxing.dart';

enum CodeOutcome { packet, other, rejected }

typedef ScannedCode = (Code code, CodeOutcome outcome);

class CodeOverlay extends StatelessWidget {
  const CodeOverlay({
    super.key,
    required this.codes,
    this.progress = 0,
    required this.controller,
  });

  final List<ScannedCode> codes;

  final double progress;

  final CameraController controller;

  // Matches flutter_zxing's MultiResultOverlay rotation.
  int _quarterTurns() {
    if (!Platform.isAndroid) return 0;
    return switch (controller.value.deviceOrientation) {
      DeviceOrientation.portraitUp || DeviceOrientation.portraitDown => 1,
      DeviceOrientation.landscapeRight => 2,
      DeviceOrientation.landscapeLeft => 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: _quarterTurns(),
      child: CustomPaint(
        painter: _CodeOverlayPainter(
          codes: codes,
          color: Theme.of(context).primaryColor,
          progress: progress.clamp(0.0, 1.0),
        ),
      ),
    );
  }
}

class _CodeOverlayPainter extends CustomPainter {
  _CodeOverlayPainter({
    required this.codes,
    required this.color,
    required this.progress,
  });

  static const _rejectedColor = Colors.redAccent;
  static const _otherColor = Color(0xFF9E9E9E);

  final List<ScannedCode> codes;
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.25);
    final progressFill = Paint()
      ..style = PaintingStyle.fill
      ..color = color
      ..blendMode = BlendMode.multiply;
    for (final (code, outcome) in codes) {
      final pos = code.position;
      if (pos == null || pos.imageWidth <= 0) continue;
      final scale = size.width / pos.imageWidth;
      final tl = Offset(pos.topLeftX * scale, pos.topLeftY * scale);
      final tr = Offset(pos.topRightX * scale, pos.topRightY * scale);
      final br = Offset(pos.bottomRightX * scale, pos.bottomRightY * scale);
      final bl = Offset(pos.bottomLeftX * scale, pos.bottomLeftY * scale);
      final path = Path()..addPolygon([tl, tr, br, bl], true);

      if (outcome == CodeOutcome.packet) canvas.drawPath(path, fill);
      stroke.color = switch (outcome) {
        CodeOutcome.packet => color,
        CodeOutcome.other => _otherColor,
        CodeOutcome.rejected => _rejectedColor,
      };
      canvas.drawPath(path, stroke);
      if (outcome == CodeOutcome.packet && progress > 0) {
        final right = Offset.lerp(br, tr, progress)!;
        final left = Offset.lerp(bl, tl, progress)!;
        canvas.drawPath(
          Path()..addPolygon([bl, br, right, left], true),
          progressFill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CodeOverlayPainter old) => true;
}
