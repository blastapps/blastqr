import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:blast_qr/extensions.dart';
import 'package:blast_qr/model/blast_qrcode_data.dart';
import 'package:blast_qr/raptorq/raptorq_encoder.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart' as mime;
import 'package:qr/qr.dart';

class FileWrapper {
  final File file;
  final FileType type;
  final int size;

  int actualTransferSize;

  String get name => file.uri.pathSegments.last;
  double get estimatedFastestTime => (size / 1000) / 20;
  double get estimatedSlowestTime => (size / 1000) / 6;
  String get sizeInkB => '${(size / 1000).toStringAsFixed(0)} KB';
  String get extension => name.split('.').last;

  bool get isCompressable =>
      !type.isVideo && !type.isWebpImage && !type.isAvifImage;

  FileWrapper({required this.file, required this.type, required this.size})
    : actualTransferSize = size;

  Future<List<QrCode>> toQrCodeList({
    required int mtu,
    required bool compressFile,
  }) async {
    // Metadata bytes (header)
    Uint8List fileExtBytes = utf8.encode(type.extension);
    if (fileExtBytes.lengthInBytes > 8) {
      // Set fileExtBytes to 0 if longer than 8 bytes
      fileExtBytes = Uint8List(8)
        ..buffer.asByteData().setUint32(0, 0, Endian.big);
    }

    final willCompressFile = compressFile && isCompressable;
    debugPrint('Splitting file. Compression enabled: $willCompressFile');
    final chunks = await _getEncodedChunks(
      mtu: mtu,
      compressFile: willCompressFile,
    );
    final transferType =
        willCompressFile
            ? BlastQRTransferType.compressedFile
            : BlastQRTransferType.rawFile;

    final sizeBytes = Uint8List(4)
      ..buffer.asByteData().setUint32(0, actualTransferSize, Endian.big);

    final List<dynamic> args = [
      chunks,
      sizeBytes,
      fileExtBytes,
      transferType.header,
    ];
    final result = compute(_encodeChunksToQr, args);
    return result;
  }

  List<QrCode> _encodeChunksToQr(List<dynamic> args) {
    final List<Uint8List> chunks = args[0];
    final Uint8List sizeBytes = args[1];
    final Uint8List fileExtBytes = args[2];
    final Uint8List transferTypeBytes = args[3];
    return chunks.map((c) {
      Uint8List combined = Uint8List(4 + 8 + 2 + 2 + c.length);
      // Encode file size in first 4 bytes
      combined.setAll(0, sizeBytes);
      // Encode file extension in followin 8 bytes
      combined.setAll(4, fileExtBytes);
      // Encode signature bytes (magic number to validate qr code) in 2 bytes
      combined.setAll(12, BlastQrcodeData.signatureBytes);
      // Encode 2 bytes for tranfsfer type (raw file, compressed file, etc)
      combined.setAll(14, transferTypeBytes);
      // Encode file data
      combined.setAll(16, c);
      return QrCode.fromUint8List(
        data: combined,
        errorCorrectLevel: QrErrorCorrectLevel.L,
      );
    }).toList();
  }

  Future<List<Uint8List>> _getEncodedChunks({
    required int mtu,
    required bool compressFile,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    var bytes = await file.readAsBytes();

    // Append filename in first 128 bytes
    final filenameBytes = name.encodeFixed128();
    bytes = Uint8List.fromList([...filenameBytes, ...bytes]);
    debugPrint('Appended filename: $name in ${filenameBytes.length} bytes');
    actualTransferSize = bytes.length;
    debugPrint('Transfer length/original: $actualTransferSize / $size');

    // Compression
    if (compressFile) {
      final compressedBytes = await compute(_compressFile, bytes);
      bytes = compressedBytes;
      actualTransferSize = compressedBytes.length;
      debugPrint('Compressed file: $size -> $actualTransferSize');
    }

    final repairPackets = (actualTransferSize / 5000);

    log('Encoding with MTU: $mtu, repairPacketsPerBlock: $repairPackets');

    final encoder = RaptorqEncoder(
      mtu: mtu,
      repairPacketsPerBlock: repairPackets.toInt(),
    );

    final encodedData = await encoder.encode(bytes);
    log('Chunk size: ${encodedData.first.length}');

    return encodedData;
  }

  Uint8List _compressFile(Uint8List original) {
    return gzip.encode(original) as Uint8List;
  }

  double getEstimateTransferTime(int speedInkBps) {
    return (size / 1000) / speedInkBps;
  }
}

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
    : isImage = mimeType?.startsWith("image") == true,
      isUnknown = mimeType == null,
      isAvifImage = mimeType == 'image/avif' || extension == 'avif',
      isWebpImage = mimeType == 'image/webp' || extension == 'webp',
      isAudio = mimeType?.startsWith("audio") == true,
      isVideo = mimeType?.startsWith("video") == true;
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
    final fileName = uri.pathSegments.last;
    final mimeType = mime.lookupMimeType(
      uri.pathSegments.last,
      headerBytes: header,
    );
    final ext = fileName.split('.').last;
    return FileType(extension: ext, mimeType: mimeType);
  }

  Future<FileWrapper> toFileWrapper() async {
    final size = await length();
    final type = await getFileType();
    return FileWrapper(file: this, type: type, size: size);
  }
}
