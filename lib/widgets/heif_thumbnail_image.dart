import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Thumbnail for HEIC/HEIF files, decoded natively off the main thread.
///
/// Flutter can't decode HEIF itself; on Android it falls back to a
/// full-resolution decode on the platform thread, which janks badly.
class HeifThumbnailImage extends ImageProvider<HeifThumbnailImage> {
  const HeifThumbnailImage(this.file, {required this.size, this.modified});

  final File file;

  /// Target length of the shorter side, in physical pixels.
  final int size;

  /// Part of the cache key so an overwritten file gets a new thumbnail.
  final DateTime? modified;

  @override
  Future<HeifThumbnailImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    HeifThumbnailImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _load(decode),
      scale: 1.0,
      debugLabel: file.path,
    );
  }

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final dimensions = await _readHeifDimensions(file);
    final bytes = await FlutterImageCompress.compressWithFile(
      file.path,
      minWidth: size,
      minHeight: size,
      quality: 85,
      inSampleSize: _sampleSize(dimensions, size),
      format: CompressFormat.jpeg,
    );
    if (bytes == null || bytes.isEmpty) {
      throw StateError('Failed to create HEIF thumbnail for ${file.path}');
    }
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  /// Largest power of two that keeps the shorter side at or above [target].
  static int _sampleSize((int, int)? dimensions, int target) {
    if (dimensions == null || target <= 0) return 1;
    final shortSide = dimensions.$1 < dimensions.$2
        ? dimensions.$1
        : dimensions.$2;
    var sample = 1;
    while (shortSide ~/ (sample * 2) >= target) {
      sample *= 2;
    }
    return sample;
  }

  /// Reads the image size from the `ispe` boxes in the file header.
  /// Gridded images (e.g. iPhone) have one per tile plus one for the
  /// full image, so the largest wins.
  static Future<(int, int)?> _readHeifDimensions(File file) async {
    const headerBytes = 128 * 1024;
    final raf = await file.open();
    final Uint8List data;
    try {
      data = await raf.read(headerBytes);
    } finally {
      await raf.close();
    }
    final view = ByteData.sublistView(data);
    (int, int)? best;
    for (var i = 0; i + 16 <= data.length; i++) {
      if (data[i] == 0x69 && // i
          data[i + 1] == 0x73 && // s
          data[i + 2] == 0x70 && // p
          data[i + 3] == 0x65) {
        // e
        final w = view.getUint32(i + 8);
        final h = view.getUint32(i + 12);
        if (best == null || w * h > best.$1 * best.$2) best = (w, h);
      }
    }
    return best;
  }

  @override
  bool operator ==(Object other) =>
      other is HeifThumbnailImage &&
      other.file.path == file.path &&
      other.size == size &&
      other.modified == modified;

  @override
  int get hashCode => Object.hash(file.path, size, modified);
}
