import 'dart:math';

import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ScanProgressWidget extends StatefulWidget {
  const ScanProgressWidget({
    super.key,
    required this.progress,
    required this.info,
    required this.onTapCancel,
    required this.chunkCount,
    required this.speed,
    required this.show,
  });

  final double progress;
  final String info;
  final int chunkCount;
  final double speed;
  final bool show;
  final void Function() onTapCancel;

  @override
  State<ScanProgressWidget> createState() => _ScanProgressWidgetState();
}

class _ScanProgressWidgetState extends State<ScanProgressWidget> {
  final Map<int, double> _speeds = {};

  double _topSpeed = 0;

  @override
  void didUpdateWidget(covariant ScanProgressWidget oldWidget) {
    // Reset state
    if (widget.progress < oldWidget.progress) {
      _speeds.clear();
      _topSpeed = 0;
    }

    final bucket = (widget.progress.clamp(0, 1) * 100).toInt();
    _speeds[bucket] = widget.speed;
    if (widget.speed > _topSpeed) {
      _topSpeed = widget.speed;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          child:
              Container(
                    height: 72,
                    alignment: Alignment.center,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(36),
                      color: context.color.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(45),
                          spreadRadius: 0,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: SizedBox(
                            height: 72,
                            child: CustomPaint(
                              painter: _SpeedGraphPainter(
                                color: context.color.primary,
                                values: _speeds,
                                max: _topSpeed,
                                progress: widget.progress,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                          child: Row(
                            spacing: 8,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: CircularProgressIndicator(
                                      strokeCap: StrokeCap.round,
                                      value: widget.progress > 1
                                          ? null
                                          : widget.progress,
                                      color: context.color.primary,
                                      backgroundColor: context.color.outline,
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: context.color.surface,
                                    ),
                                    width: 44,
                                    height: 44,
                                  ),
                                  Text(
                                    '${(widget.progress.clamp(0, 1) * 100).floor()}%',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'Jersey25',
                                      color: context.color.onSurface,
                                      height: 1,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.progress > 1
                                        ? context.l10n.keep_scanning_msg
                                        : widget.info,
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontFamily: 'Jersey25',
                                      color: context.color.onSurface,
                                      height: 1,
                                    ),
                                  ),
                                  Text(
                                    '${widget.chunkCount} | ${widget.speed.toStringAsFixed(1)}kB/s',
                                    style: TextStyle(
                                      color: context.color.onSurface,
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                                ],
                              ),
                              IconButton(
                                onPressed: widget.onTapCancel,
                                style: IconButton.styleFrom(
                                  minimumSize: const Size(24, 24),
                                  maximumSize: const Size(32, 32),
                                  backgroundColor:
                                      context.color.primaryContainer,
                                  foregroundColor: context.color.onSurface,
                                ),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.clear, size: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate(target: widget.show ? 1 : 0)
                  .fade()
                  .slideY(
                    begin: 0.75,
                    end: 0,
                    duration: 300.ms,
                    curve: Curves.easeOutBack,
                  ),
        ),
        // The bottom tabs overlap the page on phones; desktop has none.
        SizedBox(height: max(16, MediaQuery.of(context).padding.bottom - 64)),
      ],
    );
  }
}

class _SpeedGraphPainter extends CustomPainter {
  const _SpeedGraphPainter({
    required this.color,
    required this.values,
    required this.max,
    required this.progress,
  });

  final Color color;
  final Map<int, double> values;
  final double max;
  final double progress;

  static const _spacing = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (max <= 0 || values.isEmpty || progress == 0.0) return;
    final trackPaint = Paint()..color = color.withAlpha(25);
    final barPaint = Paint()..color = color.withAlpha(80);
    final yScale = size.height / max;
    final lineWidth = (size.width - (100 * _spacing)) / 100;

    var speedAtP = 0.0;
    for (var dp = 0; dp < 100; dp++) {
      if (dp > (progress * 100)) {
        break;
      }
      double x = dp * (lineWidth + _spacing);
      canvas.drawRect(
        Rect.fromLTWH(x, size.height, lineWidth, -size.height),
        trackPaint,
      );

      speedAtP = values[dp] ?? speedAtP;
      canvas.drawRect(
        Rect.fromLTWH(x, size.height, lineWidth, -(speedAtP * yScale)),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_SpeedGraphPainter old) =>
      old.progress != progress || old.max != max || old.color != color;
}
