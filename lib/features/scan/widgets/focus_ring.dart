import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FocusRing extends StatelessWidget {
  const FocusRing({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child:
          Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              )
              .animate(onComplete: (_) => onComplete())
              .scale(
                begin: const Offset(1.4, 1.4),
                duration: 200.ms,
                curve: Curves.easeOut,
              )
              .then(delay: 600.ms)
              .fadeOut(duration: 300.ms),
    );
  }
}
