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
      final ImageProvider image = type.isHeifImage
          ? HeifThumbnailImage(
              file,
              size: (size * pixelRatio).toInt(),
              modified: modified,
            )
          : ResizeImage(FileImage(file), width: (size * pixelRatio).toInt());
      return _ImageThumbnail(image: image, size: size);
    }
    return FileTypeIconWidget(type: type, size: size);
  }
}

class _ImageThumbnail extends StatefulWidget {
  const _ImageThumbnail({required this.image, required this.size});

  final ImageProvider image;
  final double size;

  @override
  State<_ImageThumbnail> createState() => _ImageThumbnailState();
}

class _ImageThumbnailState extends State<_ImageThumbnail> {
  /// Images at least this many times wider than tall aren't cropped.
  static const _wideRatio = 2.0;

  ImageStream? _stream;
  late final _listener = ImageStreamListener((info, _) {
    final wide = info.image.width / info.image.height >= _wideRatio;
    if (wide != _wide) setState(() => _wide = wide);
  });
  var _wide = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(_ImageThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) _resolve();
  }

  void _resolve() {
    final stream = widget.image.resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    _stream?.removeListener(_listener);
    _stream = stream..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return Image(
      image: widget.image,
      width: size,
      height: size,
      fit: _wide ? BoxFit.fitWidth : BoxFit.cover,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (frame == null) {
          return SizedBox.square(
            dimension: size,
            child: Icon(Icons.image, size: size / 2),
          );
        }
        return CustomPaint(
          painter: _CheckerboardPainter(
            base: Colors.white,
            alt: const Color(0xFFEBEBEB),
            cell: (size / 8).clamp(4, 12),
          ),
          child: child,
        );
      },
    );
  }
}

/// Shows through transparent pixels of image thumbnails.
class _CheckerboardPainter extends CustomPainter {
  const _CheckerboardPainter({
    required this.base,
    required this.alt,
    required this.cell,
  });

  final Color base;
  final Color alt;
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    final paint = Paint()..color = alt;
    for (var y = 0; y * cell < size.height; y++) {
      for (var x = y.isEven ? 0 : 1; x * cell < size.width; x += 2) {
        canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_CheckerboardPainter old) =>
      old.base != base || old.alt != alt || old.cell != cell;
}
