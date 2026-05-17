import 'dart:io';

import 'package:blast_qr/model/file_type.dart';
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
