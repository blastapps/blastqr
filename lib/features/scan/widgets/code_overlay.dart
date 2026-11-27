import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_zxing/flutter_zxing.dart';

enum CodeOutcome { packet, other, rejected }

typedef ScannedCode = (Code code, CodeOutcome outcome);

class CodeOverlay extends StatefulWidget {
  const CodeOverlay({
    super.key,
    required this.codes,
    this.progress = 0,
    required this.controller,
  });

  /// A new list is a new frame.
  final List<ScannedCode> codes;

  final double progress;

  final CameraController controller;

  @override
  State<CodeOverlay> createState() => _CodeOverlayState();
}

class _CodeOverlayState extends State<CodeOverlay>
    with SingleTickerProviderStateMixin {
  static const _holdFor = Duration(milliseconds: 150);
  static const _fadeFor = Duration(milliseconds: 350);

  final _clock = Stopwatch()..start();
  final _repaint = ValueNotifier(0);
  late final Ticker _ticker;
  var _shown = <_Shown>[];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => _expire());
    _ingest();
  }

  @override
  void didUpdateWidget(CodeOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) _shown = [];
    if (!identical(oldWidget.codes, widget.codes)) _ingest();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  void _ingest() {
    final now = _clock.elapsed;
    final old = _shown;
    _shown = [];
    for (final (code, outcome) in widget.codes) {
      final pos = code.position;
      if (pos == null || pos.imageWidth <= 0) continue;
      final shown = _Shown(code, outcome, now);
      final reach =
          (Offset(pos.bottomRightX.toDouble(), pos.bottomRightY.toDouble()) -
                  Offset(pos.topLeftX.toDouble(), pos.topLeftY.toDouble()))
              .distance /
          2;
      old.removeWhere((s) => (s.center - shown.center).distance < reach);
      _shown.add(shown);
    }
    // Codes not seen in this frame stay on to fade out.
    _shown.addAll(old);
    _expire();
  }

  void _expire() {
    final now = _clock.elapsed;
    _shown.removeWhere((s) => now - s.lastSeen > _holdFor + _fadeFor);
    if (_shown.isEmpty) {
      if (_ticker.isActive) _ticker.stop();
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
    _repaint.value++;
  }

  double _opacity(_Shown s) {
    final faded = _clock.elapsed - s.lastSeen - _holdFor;
    if (faded <= Duration.zero) return 1;
    return (1 - faded.inMicroseconds / _fadeFor.inMicroseconds).clamp(0, 1);
  }

  // Matches flutter_zxing's MultiResultOverlay rotation.
  int _quarterTurns() {
    if (!Platform.isAndroid) return 0;
    return switch (widget.controller.value.deviceOrientation) {
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
          shown: _shown,
          opacity: _opacity,
          color: Theme.of(context).primaryColor,
          progress: widget.progress.clamp(0.0, 1.0),
          repaint: _repaint,
        ),
      ),
    );
  }
}

class _Shown {
  _Shown(this.code, this.outcome, this.lastSeen)
    : center = Offset(
        (code.position!.topLeftX + code.position!.bottomRightX) / 2,
        (code.position!.topLeftY + code.position!.bottomRightY) / 2,
      );

  final Code code;
  final CodeOutcome outcome;
  final Duration lastSeen;
  final Offset center;
}

class _CodeOverlayPainter extends CustomPainter {
  _CodeOverlayPainter({
    required this.shown,
    required this.opacity,
    required this.color,
    required this.progress,
    required super.repaint,
  });

  static const _rejectedColor = Colors.redAccent;
  static const _otherColor = Color(0xFF9E9E9E);

  final List<_Shown> shown;
  final double Function(_Shown) opacity;
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..style = PaintingStyle.fill;
    for (final s in shown) {
      final pos = s.code.position!;
      final a = opacity(s);
      final scale = size.width / pos.imageWidth;
      final tl = Offset(pos.topLeftX * scale, pos.topLeftY * scale);
      final tr = Offset(pos.topRightX * scale, pos.topRightY * scale);
      final br = Offset(pos.bottomRightX * scale, pos.bottomRightY * scale);
      final bl = Offset(pos.bottomLeftX * scale, pos.bottomLeftY * scale);
      final path = Path()..addPolygon([tl, tr, br, bl], true);

      if (a < 1) {
        stroke.color = color.withValues(alpha: a);
        _drawDashed(canvas, path, stroke);
        continue;
      }
      if (s.outcome == CodeOutcome.packet) {
        fill.color = color.withValues(alpha: 0.25);
        canvas.drawPath(path, fill);
      }
      stroke.color = switch (s.outcome) {
        CodeOutcome.packet => color,
        CodeOutcome.other => _otherColor,
        CodeOutcome.rejected => _rejectedColor,
      };
      canvas.drawPath(path, stroke);
      if (s.outcome == CodeOutcome.packet && progress > 0) {
        final right = Offset.lerp(br, tr, progress)!;
        final left = Offset.lerp(bl, tl, progress)!;
        fill.color = color.withValues(alpha: 0.5);
        canvas.drawPath(Path()..addPolygon([bl, br, right, left], true), fill);
      }
    }
  }

  static void _drawDashed(Canvas canvas, Path path, Paint paint) {
    const dash = 10.0;
    const gap = 6.0;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        canvas.drawPath(
          metric.extractPath(d, min(d + dash, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CodeOverlayPainter old) => true;
}
