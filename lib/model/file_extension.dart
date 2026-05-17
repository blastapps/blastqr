import 'dart:io';
import 'dart:typed_data';

import 'package:blast_qr/model/file_type.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:mime/mime.dart' as mime;

extension FileExtension on File {
  Future<Uint8List> readHeaderBytes() async {
    final raf = await open();
    final headerBytes = await raf.read(mime.defaultMagicNumbersMaxLength);
    await raf.close();
    return headerBytes;
  }

  Future<FileType> getFileType() async {
    final fileName = uri.pathSegments.last;
    final ext = fileName.split('.').last.toLowerCase();
    // Try extension-based lookup first — no file I/O needed
    final mimeType = mime.lookupMimeType(fileName);
    if (mimeType != null) {
      return FileType(extension: ext, mimeType: mimeType);
    }
    // Fall back to reading magic bytes for unknown extensions
    final header = await readHeaderBytes();
    final mimeTypeFromHeader = mime.lookupMimeType(
      fileName,
      headerBytes: header,
    );
    return FileType(extension: ext, mimeType: mimeTypeFromHeader);
  }

  Future<FileWrapper> toFileWrapper() async {
    final results = await Future.wait([length(), getFileType()]);
    return FileWrapper(
      file: this,
      size: results[0] as int,
      type: results[1] as FileType,
      modified: statSync().modified,
    );
  }
}
