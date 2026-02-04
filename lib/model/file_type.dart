import 'package:flutter/material.dart';

class FileType {
  final String? mimeType;
  final String extension;
  final bool isImage;
  final bool isAudio;
  final bool isVideo;
  final bool isUnknown;
  final bool isAvifImage;
  final bool isWebpImage;

  FileType({required this.extension, required this.mimeType})
    : isImage = mimeType?.startsWith('image') == true,
      isUnknown = mimeType == null,
      isAvifImage = mimeType == 'image/avif' || extension == 'avif',
      isWebpImage = mimeType == 'image/webp' || extension == 'webp',
      isAudio = mimeType?.startsWith('audio') == true,
      isVideo = mimeType?.startsWith('video') == true;
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
