import 'dart:ui' show ImageFilter;

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

/// Up to three small thumbnails of [files] inside a box, stepping towards
/// the bottom right with the first file in front at the top left.
class StackedThumbnail extends StatelessWidget {
  const StackedThumbnail({
    super.key,
    required this.files,
    required this.size,
    this.blurred = false,
  });

  static const _maxShown = 3;

  final List<FileWrapper> files;
  final double size;
  final bool blurred;

  @override
  Widget build(BuildContext context) {
    final shown = files.take(_maxShown).toList();
    final cardSize = size * 0.55;
    final step = size * 0.11;
    final span = cardSize + step * (shown.length - 1);
    final inset = (size - span) / 2;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.color.primaryContainer,
        border: Border.all(color: context.color.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          for (var i = shown.length - 1; i >= 0; i--)
            Positioned(
              left: inset + step * i,
              top: inset + step * i,
              child: Container(
                width: cardSize,
                height: cardSize,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: context.color.primaryContainer,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(50),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(6),
                ),
                child:
                    blurred
                        ? ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                          child: shown[i].buildThumbnail(
                            context,
                            size: cardSize,
                          ),
                        )
                        : shown[i].buildThumbnail(context, size: cardSize),
              ),
            ),
        ],
      ),
    );
  }
}
