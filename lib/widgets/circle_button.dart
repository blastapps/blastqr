import 'package:blast_qr/color_scheme.dart';
import 'package:flutter/material.dart';

class CircleButton extends StatelessWidget {
  const CircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size,
    this.backgroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 4),
  });

  final Widget icon;
  final double? size;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Padding(
        padding: padding,
        child: IconButton(
          onPressed: onPressed,
          icon: icon,
          style: IconButton.styleFrom(
            backgroundColor: backgroundColor ?? context.color.primaryContainer,
            foregroundColor: context.color.onPrimaryContainer,
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.4),
            shape: const CircleBorder(),
          ),
        ),
      ),
    );
  }
}
