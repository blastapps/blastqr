import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:blast_qr/extensions.dart';
import 'package:blast_qr/features/send/helpers/qr_lookup_table.dart';
import 'package:blast_qr/model/blast_qrcode_data.dart';
import 'package:blast_qr/model/file_type.dart';
import 'package:blast_qr/model/image_compression_settings.dart';
import 'package:blast_qr/raptorq/raptorq_streaming_encoder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:mime/mime.dart' as mime;
import 'package:path/path.dart' as p;
import 'package:qr/qr.dart';

typedef QrPixelData = ({int moduleCount, Uint8List pixels});

typedef _QrBuildArgs =
    ({
      List<Uint8List> chunks,
      Uint8List sizeBytes,
      Uint8List fileExtBytes,
      Uint8List transferTypeHeader,
      int qrVersion,
    });

List<QrPixelData> _buildQrPixelsList(_QrBuildArgs args) {
  return args.chunks.map((chunk) {
    final combined = Uint8List(4 + 8 + 2 + 2 + chunk.length);
    combined.setAll(0, args.sizeBytes);
    combined.setAll(4, args.fileExtBytes);
    combined.setAll(12, BlastQrcodeData.signatureBytes);
    combined.setAll(14, args.transferTypeHeader);
    combined.setAll(16, chunk);

    final qrCode = QrCode(args.qrVersion, QrErrorCorrectLevel.L);
    qrCode.addByteData(combined.buffer.asByteData());
    final qrImage = QrImage.withMaskPattern(qrCode, 3);

    final moduleCount = qrImage.moduleCount;
    final pixels = Uint8List(moduleCount * moduleCount * 4);
    for (var row = 0; row < moduleCount; row++) {
      for (var col = 0; col < moduleCount; col++) {
        final offset = (row * moduleCount + col) * 4;
        if (qrImage.isDark(row, col)) {
          pixels[offset + 3] = 255;
        } else {
          pixels[offset] = 255;
          pixels[offset + 1] = 255;
          pixels[offset + 2] = 255;
          pixels[offset + 3] = 255;
        }
      }
    }
    return (moduleCount: moduleCount, pixels: pixels);
  }).toList();
}

/// Wrapper class to make handling files easier.
class FileWrapper {
  final File file;
  final FileType type;
  final int size;

  int _actualTransferSize;

  String get name => file.uri.pathSegments.last;
  String get nameWithoutExtension => p.basenameWithoutExtension(file.path);
  String get extension => name.split('.').last;
  String get sizeInkB => '${(size / 1000).toStringAsFixed(0)} KB';

  bool get isCompressable =>
      !type.isVideo && !type.isWebpImage && !type.isAvifImage;

  FileWrapper({required this.file, required this.type, required this.size})
    : _actualTransferSize = size;

  double getEstimateTransferTime(int speedInkBps) {
    return (size / 1000) / speedInkBps;
  }

  Stream<QrPixelData> qrImageStream(
    int mtu, {
    ImageCompressionSettings? icSettings,
  }) async* {
    final usesImageCompression = icSettings != null;

    final fileExtension =
        usesImageCompression
            ? icSettings.outputFormat.extension ?? type.extension
            : type.extension;

    // Metadata bytes (header)
    Uint8List fileExtBytes = utf8.encode(fileExtension);
    if (fileExtBytes.lengthInBytes > 8) {
      // Set fileExtBytes to 0 if longer than 8 bytes
      fileExtBytes = Uint8List(8)
        ..buffer.asByteData().setUint32(0, 0, Endian.big);
    }

    var bytes = await file.readAsBytes();
    var transferType = BlastQRTransferType.compressedFile;

    // Image compression
    if (usesImageCompression && type.allowsImageCompression) {
      final compressedImage = await _compressedImage(bytes, icSettings);
      if (compressedImage != null) {
        bytes = compressedImage;
        transferType = BlastQRTransferType.rawFile;
      }
    }

    // Append filename in first 128 bytes of file data
    final namePlusExtension = '$nameWithoutExtension.$fileExtension';
    final filenameBytes = namePlusExtension.encodeFixed128();
    bytes = Uint8List.fromList([...filenameBytes, ...bytes]);
    debugPrint(
      'Appended filename: $namePlusExtension in ${filenameBytes.length} bytes',
    );

    // File compression
    if (!usesImageCompression) {
      final compressedBytes = await compute(_compressedFile, bytes);
      bytes = compressedBytes;
    }
    _actualTransferSize = bytes.length;
    debugPrint('Compressed file: $size -> $_actualTransferSize');

    final repairPackets = (_actualTransferSize / 5000).clamp(0, 110);

    log('Encoding with MTU: $mtu, repairPacketsPerBlock: $repairPackets');

    final encoder = RaptorqStreamingEncoder(
      mtu: mtu,
      repairPacketsPerBlock: repairPackets.toInt(),
    );

    final sizeBytes = Uint8List(4)
      ..buffer.asByteData().setUint32(0, _actualTransferSize, Endian.big);

    final qrVersion = _pickQrVersionForPayload(mtu);
    debugPrint('Picked QR version: $qrVersion for mtu $mtu');

    final startTime = DateTime.now().millisecondsSinceEpoch;

    final chunks = await encoder.encode(bytes);
    encoder.dispose();

    final ct = DateTime.now().millisecondsSinceEpoch - startTime;
    final cts = (ct / 1000).toStringAsFixed(2);
    debugPrint('Chunks finalized in ${cts}s!!');

    final pixelList = await compute(_buildQrPixelsList, (
      chunks: chunks,
      sizeBytes: sizeBytes,
      fileExtBytes: fileExtBytes,
      transferTypeHeader: transferType.header,
      qrVersion: qrVersion,
    ));

    for (final pixelData in pixelList) {
      yield pixelData;
    }

    final elapsedTime = DateTime.now().millisecondsSinceEpoch - startTime;
    final elapsedSeconds = (elapsedTime / 1000).toStringAsFixed(2);
    debugPrint('Encoding finalized in ${elapsedSeconds}s!!');
  }

  int _pickQrVersionForPayload(int payloadBytes) {
    for (final entry in qrByteCapacityL.entries) {
      if (payloadBytes <= entry.value) {
        return entry.key < 40 ? entry.key + 1 : 40;
      }
    }
    return 40;
  }

  Future<Uint8List?> _compressedImage(
    Uint8List bytes,
    ImageCompressionSettings settings,
  ) async {
    try {
      var result = await FlutterImageCompress.compressWithList(
        bytes,
        minHeight: settings.minSize,
        minWidth: settings.minSize,
        quality: settings.quality,
        format: settings.outputFormat.toCompressFormat(),
        keepExif: true,
      );
      return result;
    } catch (e) {
      debugPrint('Image compression failed. Reverting to file compression');
      return null;
    }
  }

  Uint8List _compressedFile(Uint8List original) {
    return gzip.encode(original) as Uint8List;
  }
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
