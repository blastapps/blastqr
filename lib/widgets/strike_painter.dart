import 'package:flutter/material.dart';

/// Diagonal line over an icon to show it's off.
class StrikePainter extends CustomPainter {
  const StrikePainter({required this.color, required this.gapColor});

  final Color color;
  final Color gapColor;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 2.0;
    final start = const Offset(inset, inset);
    final end = Offset(size.width - inset, size.height - inset);
    final paint = Paint()..strokeCap = StrokeCap.round;
    canvas.drawLine(
      start,
      end,
      paint
        ..color = gapColor
        ..strokeWidth = 4.5,
    );
    canvas.drawLine(
      start,
      end,
      paint
        ..color = color
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(StrikePainter old) =>
      old.color != color || old.gapColor != gapColor;
}
