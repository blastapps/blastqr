import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:flutter/material.dart';

class FilesPreview extends StatelessWidget {
  const FilesPreview({super.key, required this.files, this.maxShown = 4});

  final List<FileWrapper> files;
  final int maxShown;

  @override
  Widget build(BuildContext context) {
    final shown = files.take(maxShown).toList();
    final hidden = files.length - shown.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 8,
      children: [
        for (final file in shown) FileThumbnail(file: file, size: 64),
        if (hidden > 0)
          Text(
            '+$hidden',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: context.color.secondary,
            ),
          ),
      ],
    );
  }
}

class FileThumbnail extends StatelessWidget {
  const FileThumbnail({super.key, required this.file, required this.size});

  final FileWrapper file;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            spreadRadius: 0,
            blurRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(12),
      ),
      child: file.buildThumbnail(context, size: size),
    );
  }
}
