import 'package:blast_qr/model/file_type.dart';
import 'package:flutter/material.dart';

class FileTypeIconWidget extends StatelessWidget {
  const FileTypeIconWidget({super.key, required this.type});

  final FileType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: type.color,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(type.icon, size: 64, color: Colors.white.withAlpha(80)),
          FittedBox(
            child: Text(
              type.extension.toUpperCase(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
