import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class HelpMessage extends StatelessWidget {
  const HelpMessage({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(64),
          color: Colors.black.withAlpha(140),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(75),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedInformationCircle,
              color: Colors.white,
            ),
            Flexible(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
