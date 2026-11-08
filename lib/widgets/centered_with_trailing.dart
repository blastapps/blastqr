import 'package:flutter/material.dart';

/// [child] centred, with [trailing] right after it. Shrinks to fit when too
/// wide.
class CenteredWithTrailing extends StatelessWidget {
  const CenteredWithTrailing({
    super.key,
    required this.child,
    this.trailing,
    this.spacing = 12,
  });

  final Widget child;
  final Widget? trailing;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;
    if (trailing == null) return child;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: spacing,
        children: [
          // An invisible copy on the other side keeps the child centred.
          Visibility(
            visible: false,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: trailing,
          ),
          child,
          trailing,
        ],
      ),
    );
  }
}
