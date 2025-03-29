import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:blast_qr/extensions.dart';
import 'package:blast_qr/model/blast_qrcode_data.dart';
import 'package:blast_qr/raptorq/raptorq_streaming_encoder.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart' as mime;
import 'package:qr/qr.dart';

class FileWrapper {
  final File file;
  final FileType type;
  final int size;

  int _actualTransferSize;

  String get name => file.uri.pathSegments.last;
  double get estimatedFastestTime => (size / 1000) / 40; // 40kb/s
  double get estimatedSlowestTime => (size / 1000) / 6;
  String get sizeInkB => '${(size / 1000).toStringAsFixed(0)} KB';
  String get extension => name.split('.').last;

  bool get isCompressable =>
      !type.isVideo && !type.isWebpImage && !type.isAvifImage;

  FileWrapper({required this.file, required this.type, required this.size})
    : _actualTransferSize = size;

  Uint8List _compressFile(Uint8List original) {
    return gzip.encode(original) as Uint8List;
  }

  double getEstimateTransferTime(int speedInkBps) {
    return (size / 1000) / speedInkBps;
  }

  QrCode _encodeChunkToQr(List<dynamic> args) {
    final Uint8List chunk = args[0];
    final Uint8List sizeBytes = args[1];
    final Uint8List fileExtBytes = args[2];
    final Uint8List transferTypeBytes = args[3];

    Uint8List combined = Uint8List(4 + 8 + 2 + 2 + chunk.length);
    // Encode file size in first 4 bytes
    combined.setAll(0, sizeBytes);
    // Encode file extension in followin 8 bytes
    combined.setAll(4, fileExtBytes);
    // Encode signature bytes (magic number to validate qr code) in 2 bytes
    combined.setAll(12, BlastQrcodeData.signatureBytes);
    // Encode 2 bytes for tranfsfer type (raw file, compressed file, etc)
    combined.setAll(14, transferTypeBytes);
    // Encode file data
    combined.setAll(16, chunk);

    return QrCode.fromUint8List(
      data: combined,
      errorCorrectLevel: QrErrorCorrectLevel.L,
    );
  }

  Stream<QrImage> qrImageStream(int mtu) async* {
    // Metadata bytes (header)
    Uint8List fileExtBytes = utf8.encode(type.extension);
    if (fileExtBytes.lengthInBytes > 8) {
      // Set fileExtBytes to 0 if longer than 8 bytes
      fileExtBytes = Uint8List(8)
        ..buffer.asByteData().setUint32(0, 0, Endian.big);
    }

    var bytes = await file.readAsBytes();

    // Append filename in first 128 bytes of file data
    final filenameBytes = name.encodeFixed128();
    bytes = Uint8List.fromList([...filenameBytes, ...bytes]);
    debugPrint('Appended filename: $name in ${filenameBytes.length} bytes');
    _actualTransferSize = bytes.length;
    debugPrint('Transfer length/original: $_actualTransferSize / $size');

    // Compression
    final compressedBytes = await compute(_compressFile, bytes);
    bytes = compressedBytes;
    _actualTransferSize = compressedBytes.length;
    debugPrint('Compressed file: $size -> $_actualTransferSize');

    final repairPackets = (_actualTransferSize / 5000);

    log('Encoding with MTU: $mtu, repairPacketsPerBlock: $repairPackets');

    final encoder = RaptorqStreamingEncoder(
      mtu: mtu,
      repairPacketsPerBlock: repairPackets.toInt(),
    );

    final transferType = BlastQRTransferType.compressedFile;

    final sizeBytes = Uint8List(4)
      ..buffer.asByteData().setUint32(0, _actualTransferSize, Endian.big);

    await for (RaptorqTransfer transfer in encoder.encode(bytes)) {
      final qr = _encodeChunkToQr([
        transfer.data,
        sizeBytes,
        fileExtBytes,
        transferType.header,
      ]);
      await Future.delayed(
        const Duration(milliseconds: 1),
      ); // Allows  UI to update
      final qrImage = QrImage.withMaskPattern(qr, 3);
      yield qrImage;

      if (transfer.isComplete) {
        debugPrint('Transfer finalized!!');
        break;
      }
    }
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
