import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class AcousticSuccessOverlay extends StatefulWidget {
  static const countdownDuration = Duration(seconds: 3);

  const AcousticSuccessOverlay({
    super.key,
    required this.onKeepShowing,
    required this.onDone,
    this.onNextFile,
  });

  final VoidCallback onKeepShowing;
  final VoidCallback onDone;
  final VoidCallback? onNextFile;

  @override
  State<AcousticSuccessOverlay> createState() => _AcousticSuccessOverlayState();
}

class _AcousticSuccessOverlayState extends State<AcousticSuccessOverlay>
    with SingleTickerProviderStateMixin {
  AnimationController? _countdown;

  @override
  void initState() {
    super.initState();
    _countdown = AnimationController(
      vsync: this,
      duration: AcousticSuccessOverlay.countdownDuration,
      value: 1.0,
    )..addStatusListener((status) {
      if (status == AnimationStatus.dismissed && mounted) {
        if (widget.onNextFile != null) {
          widget.onNextFile!();
        } else {
          widget.onDone();
        }
      }
    });
    _countdown!.reverse();
  }

  @override
  void dispose() {
    _countdown?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 36),
      color: context.color.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedCheckmarkCircle02,
            size: 72,
            color: context.color.primary,
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.transfer_complete,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: context.color.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_countdown != null) ...[
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: AnimatedBuilder(
                animation: _countdown!,
                builder:
                    (context, _) => LinearProgressIndicator(
                      value: _countdown!.value,
                      color: context.color.primary,
                      backgroundColor: context.color.surfaceContainerHighest,
                    ),
              ),
            ),
          ],
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              _countdown?.stop();
              widget.onKeepShowing();
            },
            child: Text(context.l10n.keep_showing_qr),
          ),
        ],
      ),
    );
  }
}
