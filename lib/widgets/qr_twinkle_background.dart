import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A wall of QR codes whose modules twinkle in and out, with soft patches of
/// light drifting around it, tinted with [color]. Drawn by a single fragment
/// shader (`shaders/qr_twinkle.frag`), one pass per frame.
///
/// Still when the platform asks for
/// less motion, and paused whenever tickers are muted (e.g. under another
/// route).
class QrTwinkleBackground extends StatefulWidget {
  /// The tint the modules are drawn in.
  final Color color;

  /// Overall opacity of the modules, 0 to 1.
  final double opacity;

  /// The size of one QR module, in logical pixels.
  final double cell;

  /// Where it starts fading in from nothing, measured down from the top in
  /// logical pixels: the bottom of whatever covers the top, like an app bar.
  final double fadeStart;

  /// How far below [fadeStart] it reaches full strength.
  final double fadeLength;

  const QrTwinkleBackground({
    super.key,
    required this.color,
    this.opacity = 1,
    this.cell = 5,
    this.fadeStart = 0,
    this.fadeLength = 200,
  });

  /// One full loop of the animation; every motion in the shader repeats a
  /// whole number of times in it.
  static const Duration cycle = Duration(seconds: 48);

  /// The shader, compiled once for the app.
  static final Future<ui.FragmentProgram> _program = ui
      .FragmentProgram.fromAsset('shaders/qr_twinkle.frag');

  @override
  State<QrTwinkleBackground> createState() => _QrTwinkleBackgroundState();
}

class _QrTwinkleBackgroundState extends State<QrTwinkleBackground>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);

  /// Where the animation is in its cycle, 0 to 1. The painter listens to
  /// this directly, so each frame repaints without rebuilding.
  final ValueNotifier<double> _phase = ValueNotifier(0);

  /// Where the cycle stood when the ticker was last (re)started, so a pause
  /// resumes rather than jumps.
  double _phaseAtStart = 0;

  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    QrTwinkleBackground._program.then((program) {
      if (!mounted) return;
      setState(() => _shader = program.fragmentShader());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _ticker.stop();
    } else if (!_ticker.isActive) {
      _phaseAtStart = _phase.value;
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    final cycle = QrTwinkleBackground.cycle.inMicroseconds;
    _phase.value = (_phaseAtStart + elapsed.inMicroseconds / cycle) % 1.0;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _phase.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shader = _shader;
    if (shader == null) return const SizedBox.expand();
    // Behind a boundary so each frame repaints only this.
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _QrTwinklePainter(
          shader: shader,
          phase: _phase,
          color: widget.color,
          opacity: widget.opacity,
          cell: widget.cell,
          fadeStart: widget.fadeStart,
          fadeEnd: widget.fadeStart + widget.fadeLength,
          pixel: 1 / MediaQuery.devicePixelRatioOf(context),
        ),
      ),
    );
  }
}

class _QrTwinklePainter extends CustomPainter {
  final ui.FragmentShader shader;
  final ValueNotifier<double> phase;
  final Color color;
  final double opacity;
  final double cell;
  final double fadeStart;
  final double fadeEnd;
  final double pixel;

  _QrTwinklePainter({
    required this.shader,
    required this.phase,
    required this.color,
    required this.opacity,
    required this.cell,
    required this.fadeStart,
    required this.fadeEnd,
    required this.pixel,
  }) : super(repaint: phase);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, cell)
      ..setFloat(3, pixel)
      ..setFloat(4, phase.value)
      ..setFloat(5, color.r)
      ..setFloat(6, color.g)
      ..setFloat(7, color.b)
      ..setFloat(8, color.a * opacity)
      ..setFloat(9, fadeStart)
      ..setFloat(10, fadeEnd);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_QrTwinklePainter old) =>
      old.shader != shader ||
      old.color != color ||
      old.opacity != opacity ||
      old.cell != cell ||
      old.fadeStart != fadeStart ||
      old.fadeEnd != fadeEnd ||
      old.pixel != pixel;
}
