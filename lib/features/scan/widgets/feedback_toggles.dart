import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/platform_support.dart';
import 'package:blast_qr/widgets/circle_button.dart';
import 'package:blast_qr/widgets/strike_painter.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class FeedbackToggles extends StatelessWidget {
  const FeedbackToggles({
    super.key,
    required this.appSettings,
    required this.colors,
  });

  final AppSettings appSettings;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final offColor = colors.onPrimaryContainer.withValues(alpha: 0.5);
    return Row(
      children: [
        if (!isDesktopOS)
          CircleButton(
            padding: const EdgeInsetsDirectional.only(start: 8),
            tooltip: context.l10n.haptic_feedback,
            onPressed: () {
              appSettings.updateHapticFeedback(!appSettings.hapticFeedback);
            },
            icon: CustomPaint(
              foregroundPainter: appSettings.hapticFeedback
                  ? null
                  : StrikePainter(
                      color: offColor,
                      gapColor: colors.primaryContainer,
                    ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedSmartPhone03,
                color: appSettings.hapticFeedback
                    ? colors.onPrimaryContainer
                    : offColor,
              ),
            ),
          ),
        CircleButton(
          padding: isDesktopOS
              ? const EdgeInsetsDirectional.only(start: 8)
              : EdgeInsets.zero,
          tooltip: context.l10n.sound_feedback,
          onPressed: () {
            appSettings.updateSoundFeedback(!appSettings.soundFeedback);
          },
          icon: HugeIcon(
            icon: appSettings.soundFeedback
                ? HugeIcons.strokeRoundedVolumeLow
                : HugeIcons.strokeRoundedVolumeOff,
            color: appSettings.soundFeedback
                ? colors.onPrimaryContainer
                : offColor,
          ),
        ),
      ],
    );
  }
}
