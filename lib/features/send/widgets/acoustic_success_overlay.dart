import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/widgets/password_widgets.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class AcousticSuccessOverlay extends StatefulWidget {
  static const countdownDuration = Duration(seconds: 6);

  const AcousticSuccessOverlay({
    super.key,
    required this.onKeepShowing,
    required this.onDone,
    this.password,
  });

  final VoidCallback onKeepShowing;
  final VoidCallback onDone;

  final String? password;

  @override
  State<AcousticSuccessOverlay> createState() => _AcousticSuccessOverlayState();
}

class _AcousticSuccessOverlayState extends State<AcousticSuccessOverlay>
    with SingleTickerProviderStateMixin {
  AnimationController? _countdown;
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    if (widget.password != null) return;
    _countdown =
        AnimationController(
          vsync: this,
          duration: AcousticSuccessOverlay.countdownDuration,
          value: 1.0,
        )..addStatusListener((status) {
          if (status == AnimationStatus.dismissed && mounted) {
            widget.onDone();
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
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: AnimatedBuilder(
                animation: _countdown!,
                builder: (context, _) => LinearProgressIndicator(
                  value: _countdown!.value,
                  color: context.color.primary,
                  backgroundColor: context.color.surfaceContainerHighest,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (widget.password != null) ...[
            const SizedBox(height: 24),
            if (_passwordVisible) ...[
              GestureDetector(
                onTap: () => setState(() => _passwordVisible = false),
                child: SizedBox(
                  height: 48,
                  child: Center(
                    child: Text(
                      widget.password!,
                      textAlign: TextAlign.center,
                      style: passwordTextStyle(context, fontSize: 28),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ] else ...[
              OutlinedButton.icon(
                onPressed: () => setState(() => _passwordVisible = true),
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedSquareLock02,
                  size: 18,
                  color: context.color.onSurface,
                ),
                label: Text(context.l10n.show_password),
              ),
              const SizedBox(height: 8),
            ],
          ],
          if (widget.password != null)
            OutlinedButton(
              onPressed: widget.onKeepShowing,
              child: Text(context.l10n.keep_showing_qr),
            )
          else
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
