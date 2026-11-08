import 'package:flutter/material.dart';

class FileType {
  static const documentExtensions = ['pdf', 'docx', 'doc', 'odt', 'hwp'];

  final String? mimeType;
  final String extension;
  final bool isImage;
  final bool isAudio;
  final bool isDocument;
  final bool isVideo;
  final bool isUnknown;
  final bool isAvifImage;
  final bool isWebpImage;
  final bool isHeifImage;
  final bool isEbook;

  FileType({required this.extension, required this.mimeType})
    : isImage = mimeType?.startsWith('image') == true,
      isUnknown = mimeType == null,
      isAvifImage = mimeType == 'image/avif' || extension == 'avif',
      isWebpImage = mimeType == 'image/webp' || extension == 'webp',
      isHeifImage =
          mimeType?.startsWith('image/hei') == true ||
          extension == 'heic' ||
          extension == 'heif',
      isDocument = documentExtensions.contains(extension),
      isAudio = mimeType?.startsWith('audio') == true,
      isVideo = mimeType?.startsWith('video') == true,
      isEbook =
          extension == 'epub' ||
          mimeType?.contains('ebook') == true ||
          mimeType?.contains('epub') == true;

  /// GIF is left out to keep its animation, AVIF as it doesn't decode
  /// reliably.
  bool get allowsImageCompression =>
      isHeifImage ||
      isWebpImage ||
      mimeType == 'image/jpeg' ||
      mimeType == 'image/png' ||
      const ['jpg', 'jpeg', 'png'].contains(extension);

  bool get isPrecompressed => isAudio || isVideo;
}

extension FileTypeExtension on FileType {
  IconData get icon {
    if (isImage) {
      return Icons.image;
    } else if (isVideo) {
      return Icons.video_file;
    } else if (isAudio) {
      return Icons.audio_file;
    }
    return Icons.description;
  }

  Color get color {
    if (isImage) {
      return Colors.deepOrangeAccent;
    } else if (isVideo) {
      return Colors.deepPurpleAccent;
    } else if (isAudio) {
      return Colors.blueAccent;
    }
    return Colors.grey;
  }
}
