import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/widgets/strike_painter.dart';
import 'package:flutter/material.dart';

/// Tapping switches [hd]: on sends photos as they are, off compresses them.
class HdToggle extends StatelessWidget {
  const HdToggle({super.key, required this.hd});

  final ValueNotifier<bool> hd;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: hd,
      builder: (context, on, _) {
        final color = on
            ? context.color.primary
            : context.color.secondary.withValues(alpha: 0.5);
        return Tooltip(
          message: context.l10n.hd_tooltip,
          child: Semantics(
            button: true,
            toggled: on,
            child: CustomPaint(
              foregroundPainter: on
                  ? null
                  : StrikePainter(
                      color: color,
                      gapColor: context.color.primaryContainer,
                    ),
              child: Material(
                color: on ? color : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(color: color, width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => hd.value = !on,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      'HD',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: on ? context.color.onPrimary : color,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
