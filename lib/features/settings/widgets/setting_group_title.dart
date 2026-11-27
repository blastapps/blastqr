import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/theme.dart';
import 'package:flutter/material.dart';

class SettingGroupTitle extends StatelessWidget {
  const SettingGroupTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Text(
        title,
        style: pixelTextStyle.copyWith(
          color: context.color.primary,
          fontSize: 17,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
