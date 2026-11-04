import 'dart:async';

import 'package:blast_qr/color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

const passwordRevealDuration = Duration(seconds: 10);

class PasswordButton extends StatefulWidget {
  const PasswordButton({super.key, required this.password});

  final String password;

  @override
  State<PasswordButton> createState() => _PasswordButtonState();
}

class _PasswordButtonState extends State<PasswordButton> {
  bool _visible = false;
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _setVisible(bool visible) {
    _hideTimer?.cancel();
    if (visible) {
      _hideTimer = Timer(passwordRevealDuration, () => _setVisible(false));
    }
    setState(() => _visible = visible);
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () => _setVisible(!_visible),
      child: Row(
        spacing: 8,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedSquareLock02,
            size: 20,
            color: context.color.onSurface,
          ),
          Expanded(
            child: Text(
              _visible ? widget.password : '••••-••••-••••',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: passwordTextStyle(context),
            ),
          ),
          HugeIcon(
            icon: _visible
                ? HugeIcons.strokeRoundedViewOff
                : HugeIcons.strokeRoundedView,
            size: 20,
            color: context.color.onSurface,
          ),
        ],
      ),
    );
  }
}

TextStyle? passwordTextStyle(BuildContext context, {double fontSize = 18}) {
  return Theme.of(context).textTheme.titleMedium?.copyWith(
    fontFamily: 'monospace',
    fontFamilyFallback: const ['Menlo', 'Roboto Mono', 'Courier'],
    fontSize: fontSize,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
  );
}
