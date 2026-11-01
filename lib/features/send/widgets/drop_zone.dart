import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Desktop: a dashed area to drop files on, or click to pick them.
class DropZone extends StatelessWidget {
  const DropZone({super.key, required this.highlighted, required this.onTap});

  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = context.color.primary;
    return CustomPaint(
      foregroundPainter: _DashedBorderPainter(
        color: highlighted ? accent : accent.withValues(alpha: 0.5),
        width: highlighted ? 2 : 1.5,
        radius: radius.topLeft,
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: highlighted
                ? Color.alphaBlend(
                    accent.withValues(alpha: isDark ? 0.2 : 0.08),
                    context.cardFill,
                  )
                : context.cardFill.withValues(alpha: 0.85),
            borderRadius: radius,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.25 : 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedFileAdd,
                  color: accent,
                  size: 36,
                ),
              ),
              Text(
                context.l10n.drop_files,
                style: const TextStyle(fontFamily: 'Jersey25', fontSize: 28),
              ),
              Text(
                context.l10n.drop_files_subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.color.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.width,
    required this.radius,
  });

  final Color color;
  final double width;
  final Radius radius;

  static const _dash = 8.0;
  static const _gap = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(width / 2);
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, radius));
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += _dash + _gap) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.width != width || old.radius != radius;
}

/// Phone recents: tap sends a file, long-press starts selecting several.
