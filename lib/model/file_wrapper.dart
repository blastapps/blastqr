import 'dart:io';
import 'dart:typed_data';

import 'package:mime/mime.dart' as mime;

class FileWrapper {
  final File file;
  final FileType type;
  final int size;

  String get name => file.uri.pathSegments.last;
  double get estimatedFastestTime => (size / 1000) / 20;
  double get estimatedSlowestTime => (size / 1000) / 6;
  String get sizeInkB => '${(size / 1000).toStringAsFixed(0)} KB';
  String get extension => name.split('.').last;

  FileWrapper({required this.file, required this.type, required this.size});

  double getEstimateTransferTime(int speedInkBps) {
    return (size / 1000) / speedInkBps;
  }
}

class FileType {
  final String? mimeType;
  final bool isImage;
  final bool isUnknown;
  final bool isAvifImage;

  FileType({required this.mimeType})
    : isImage = mimeType?.startsWith("image") == true,
      isUnknown = mimeType == null,
      isAvifImage = mimeType == 'image/avif';
}

extension FileExtension on File {
  Future<Uint8List> readHeaderBytes() async {
    final raf = await open();
    final headerBytes = await raf.read(mime.defaultMagicNumbersMaxLength);
    await raf.close();
    return headerBytes;
  }

  Future<FileType> getFileType() async {
    final header = await readHeaderBytes();
    final mimeType = mime.lookupMimeType(
      uri.pathSegments.last,
      headerBytes: header,
    );
    return FileType(mimeType: mimeType);
  }

  Future<FileWrapper> toFileWrapper() async {
    final size = await length();
    final type = await getFileType();
    return FileWrapper(file: this, type: type, size: size);
  }
}
