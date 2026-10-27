import 'dart:io';

import 'package:blast_qr/model/file_type.dart';
import 'package:blast_qr/widgets/file_type_icon_widget.dart';
import 'package:blast_qr/widgets/heif_thumbnail_image.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

/// Wrapper class to make handling files easier.
class FileWrapper {
  final File file;
  final FileType type;
  final int size;

  String get name => file.uri.pathSegments.last;
  String get nameWithoutExtension => p.basenameWithoutExtension(file.path);
  String get extension => name.split('.').last;
  String get sizeInkB => '${(size / 1000).toStringAsFixed(0)} KB';

  bool get isCompressable =>
      !type.isVideo && !type.isWebpImage && !type.isAvifImage;

  final DateTime modified;

  FileWrapper({
    required this.file,
    required this.type,
    required this.size,
    required this.modified,
  });

  double getEstimateTransferTime(int speedInkBps) {
    return (size / 1000) / speedInkBps;
  }
}

extension FileWrapperThumbnailExtension on FileWrapper {
  Widget buildThumbnail(BuildContext context, {required double size}) {
    if (type.isImage && !type.isAvifImage) {
      final pixelRatio = MediaQuery.of(context).devicePixelRatio;
      return Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.image, size: size / 2),
          if (type.isHeifImage)
            Image(
              image: HeifThumbnailImage(
                file,
                size: (size * pixelRatio).toInt(),
                modified: modified,
              ),
              width: size,
              height: size,
              fit: BoxFit.cover,
            )
          else
            Image.file(
              file,
              width: size,
              height: size,
              fit: BoxFit.cover,
              cacheWidth: (size * pixelRatio).toInt(),
            ),
        ],
      );
    }
    return FileTypeIconWidget(type: type, size: size);
  }
}
