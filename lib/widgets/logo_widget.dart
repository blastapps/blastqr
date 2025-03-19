import 'package:blast_qr/color_scheme.dart';
import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  const LogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(
          context,
        ).textTheme.displayMedium?.copyWith(fontFamily: 'Jersey25'),
        children: [
          TextSpan(text: 'BLAST'),
          TextSpan(text: 'QR', style: TextStyle(color: context.color.primary)),
        ],
      ),
    );
  }
}
