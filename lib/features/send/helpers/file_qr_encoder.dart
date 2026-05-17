import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:blast_qr/extensions.dart';
import 'package:blast_qr/features/send/helpers/qr_lookup_table.dart';
import 'package:blast_qr/model/blast_qrcode_data.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blast_qr/model/image_compression_settings.dart';
import 'package:blast_qr/raptorq/raptorq_streaming_encoder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
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

void _buildQrPixelsBatched(({_QrBuildArgs args, SendPort sendPort}) message) {
  final args = message.args;
  final sendPort = message.sendPort;

  for (final chunk in args.chunks) {
    final combined = Uint8List(3 + 1 + 4 + 4 + 2 + chunk.length);
    combined.setAll(0, BlastQrcodeData.signatureBytes);
    combined[3] = BlastQrcodeData.protocolVersion;
    combined.setAll(4, args.sizeBytes);
    combined.setAll(8, args.fileExtBytes);
    combined.setAll(12, args.transferTypeHeader);
    combined.setAll(14, chunk);

    final qrCode = QrCode(args.qrVersion, QrErrorCorrectLevel.L);
    qrCode.addByteData(combined.buffer.asByteData());
    final qrImage = QrImage.withMaskPattern(qrCode, 3);

    // We pre-render to raw RGBA pixels rather than passing QrImage directly
    // so the pixel buffer can be decoded into a ui.Image on the UI isolate
    // via ui.decodeImageFromPixels — avoiding repeated per-frame QR module
    // traversal during animation.
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
    // TransferableTypedData transfers ownership of the buffer to the main
    // isolate without copying, keeping throughput on par with compute().
    sendPort.send((
      moduleCount: moduleCount,
      pixels: TransferableTypedData.fromList([pixels]),
    ));
  }
  sendPort.send(null); // signals completion
}

Uint8List _gzipCompress(Uint8List original) {
  return gzip.encode(original) as Uint8List;
}

class FileQrEncoder {
  const FileQrEncoder._();

  static Stream<QrPixelData> encode(
    FileWrapper file,
    int mtu, {
    ImageCompressionSettings? icSettings,
  }) async* {
    final usesImageCompression = icSettings != null;

    final fileExtension =
        usesImageCompression
            ? icSettings.outputFormat.extension ?? file.type.extension
            : file.type.extension;

    // Metadata bytes (header)
    Uint8List fileExtBytes = utf8.encode(fileExtension);
    if (fileExtBytes.lengthInBytes > 4) {
      // Set fileExtBytes to 0 if longer than 4 bytes
      fileExtBytes = Uint8List(4);
    } else if (fileExtBytes.lengthInBytes < 4) {
      final padded = Uint8List(4);
      padded.setAll(0, fileExtBytes);
      fileExtBytes = padded;
    }

    var bytes = await file.file.readAsBytes();
    // Videos are already codec-compressed; gzip yields negligible savings.
    var compression =
        file.type.isVideo ? BlastQrCompression.none : BlastQrCompression.gzip;

    // Image compression
    if (usesImageCompression && file.type.allowsImageCompression) {
      final compressedImage = await _compressImage(bytes, icSettings);
      if (compressedImage != null) {
        bytes = compressedImage;
        compression = BlastQrCompression.none;
      }
    }

    // Append filename in first 128 bytes of file data
    final namePlusExtension = '${file.nameWithoutExtension}.$fileExtension';
    final filenameBytes = namePlusExtension.encodeFixed128();
    bytes = Uint8List.fromList([...filenameBytes, ...bytes]);
    debugPrint(
      'Appended filename: $namePlusExtension in ${filenameBytes.length} bytes',
    );

    // File compression
    if (compression == BlastQrCompression.gzip) {
      bytes = await compute(_gzipCompress, bytes);
    }
    final actualTransferSize = bytes.length;
    debugPrint('Compressed file: ${file.size} -> $actualTransferSize');

    // Any K out of (K + repairPackets) symbols decodes successfully.
    // At 60% redundancy the receiver only needs to scan ~62.5% of QR frames.
    final sourceSymbols = (actualTransferSize / mtu).ceil();
    final repairPackets = (sourceSymbols * 0.64).toInt();

    log('Encoding with MTU: $mtu, repairPacketsPerBlock: $repairPackets');

    final encoder = RaptorqStreamingEncoder(
      mtu: mtu,
      repairPacketsPerBlock: repairPackets,
    );

    final sizeBytes = Uint8List(4)
      ..buffer.asByteData().setUint32(0, actualTransferSize, Endian.big);

    final qrVersion = _pickQrVersion(mtu);
    debugPrint('Picked QR version: $qrVersion for mtu $mtu');

    final startTime = DateTime.now().millisecondsSinceEpoch;

    final chunks = await encoder.encode(bytes);
    encoder.dispose();

    final ct = DateTime.now().millisecondsSinceEpoch - startTime;
    final cts = (ct / 1000).toStringAsFixed(2);
    debugPrint('Chunks finalized in ${cts}s!!');

    final receivePort = ReceivePort();
    await Isolate.spawn(_buildQrPixelsBatched, (
      args: (
        chunks: chunks,
        sizeBytes: sizeBytes,
        fileExtBytes: fileExtBytes,
        transferTypeHeader: compression.header,
        qrVersion: qrVersion,
      ),
      sendPort: receivePort.sendPort,
    ));

    await for (final message in receivePort) {
      if (message == null) {
        receivePort.close();
        break;
      }
      final msg = message as ({int moduleCount, TransferableTypedData pixels});
      yield (
        moduleCount: msg.moduleCount,
        pixels: msg.pixels.materialize().asUint8List(),
      );
    }

    final elapsedTime = DateTime.now().millisecondsSinceEpoch - startTime;
    final elapsedSeconds = (elapsedTime / 1000).toStringAsFixed(2);
    debugPrint('Encoding finalized in ${elapsedSeconds}s!!');
  }

  static int _pickQrVersion(int payloadBytes) {
    for (final entry in qrByteCapacityL.entries) {
      if (payloadBytes <= entry.value) {
        return entry.key < 40 ? entry.key + 1 : 40;
      }
    }
    return 40;
  }

  static Future<Uint8List?> _compressImage(
    Uint8List bytes,
    ImageCompressionSettings settings,
  ) async {
    try {
      return await FlutterImageCompress.compressWithList(
        bytes,
        minHeight: settings.minSize,
        minWidth: settings.minSize,
        quality: settings.quality,
        format: settings.outputFormat.toCompressFormat(),
        keepExif: true,
      );
    } catch (e) {
      debugPrint('Image compression failed. Reverting to file compression');
      return null;
    }
  }
}
