import 'dart:convert';

import 'package:flutter/foundation.dart';

enum QrEncodingType { bytes, base45, base64 }

enum BlastQRTransferType {
  rawFile,
  compressedFile;

  static final _rawFileHeader = Uint8List.fromList([0, 1]);
  static final _compressedFileHeader = Uint8List.fromList([0, 2]);

  Uint8List get header {
    switch (this) {
      case BlastQRTransferType.rawFile:
        return _rawFileHeader;
      case BlastQRTransferType.compressedFile:
        return _compressedFileHeader;
    }
  }

  static BlastQRTransferType fromBytes(Uint8List bytes) {
    if (bytes[0] == _compressedFileHeader[0] &&
        bytes[1] == _compressedFileHeader[1]) {
      return BlastQRTransferType.compressedFile;
    }
    return BlastQRTransferType.rawFile;
  }
}

class BlastQrcodeData {
  static final signatureBytes = Uint8List.fromList([81, 45]);
  static final int headerLength = 16;

  final int transferLength;
  final String fileExtension;
  final Uint8List data;
  final int mtu;
  final bool isCompressedData;

  BlastQrcodeData({
    required this.transferLength,
    required this.fileExtension,
    required this.data,
    required this.mtu,
    required this.isCompressedData,
  });

  factory BlastQrcodeData.fromBytes(Uint8List bytes) {
    if (!bytesIsValidBlastQrCode(bytes)) {
      throw Exception('Not a valid BlastQR code.');
    }
    ByteData sizeByteData = bytes.buffer.asByteData(0, 4);
    Uint8List extBytes = bytes.sublist(4, 12);
    int fileSize = sizeByteData.getUint32(0, Endian.big);
    Uint8List transferTypeBytes = bytes.sublist(14, 16);
    int mtu = bytes.length - headerLength;

    final transferType = BlastQRTransferType.fromBytes(transferTypeBytes);
    String ext = utf8
        .decode(extBytes, allowMalformed: false)
        .replaceAll('\x00', '');
    Uint8List packetBytes = bytes.sublist(headerLength);

    return BlastQrcodeData(
      transferLength: fileSize,
      fileExtension: ext,
      data: packetBytes,
      mtu: mtu,
      isCompressedData: transferType == BlastQRTransferType.compressedFile,
    );
  }

  static bool bytesIsValidBlastQrCode(Uint8List? bytes) {
    if (bytes == null) {
      return false;
    }
    Uint8List signature = bytes.sublist(12, 14);
    return (signature[0] == signatureBytes[0] &&
        signature[1] == signatureBytes[1]);
  }
}
