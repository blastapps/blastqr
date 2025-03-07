import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  const LogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.titleLarge,
        children: [
          TextSpan(
            text: 'BLAST',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: 'QR', style: TextStyle(fontWeight: FontWeight.w300)),
        ],
      ),
    );
  }
}
