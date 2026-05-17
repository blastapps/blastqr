import 'dart:convert';

import 'package:flutter/foundation.dart';

enum QrEncodingType { bytes, base45, base64 }

enum BlastQrCompression {
  none,
  gzip;

  static final _rawFileHeader = Uint8List.fromList([0, 1]);
  static final _compressedFileHeader = Uint8List.fromList([0, 2]);

  Uint8List get header {
    switch (this) {
      case BlastQrCompression.none:
        return _rawFileHeader;
      case BlastQrCompression.gzip:
        return _compressedFileHeader;
    }
  }

  static BlastQrCompression fromBytes(Uint8List bytes) {
    if (bytes[0] == _compressedFileHeader[0] &&
        bytes[1] == _compressedFileHeader[1]) {
      return BlastQrCompression.gzip;
    }
    return BlastQrCompression.none;
  }
}

class BlastQrcodeData {
  // "BQR" — 3-byte magic at offset 0 for fast frame identification
  static final signatureBytes = Uint8List.fromList([0x42, 0x51, 0x52]);
  static const int protocolVersion = 1;
  static final int headerLength = 14;

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
    ByteData sizeByteData = bytes.buffer.asByteData(4, 4);
    Uint8List extBytes = bytes.sublist(8, 12);
    int fileSize = sizeByteData.getUint32(0, Endian.big);
    Uint8List transferTypeBytes = bytes.sublist(12, 14);
    int mtu = bytes.length - headerLength;

    final transferType = BlastQrCompression.fromBytes(transferTypeBytes);
    String ext = utf8
        .decode(extBytes, allowMalformed: false)
        .replaceAll('\x00', '');
    Uint8List packetBytes = bytes.sublist(headerLength);

    return BlastQrcodeData(
      transferLength: fileSize,
      fileExtension: ext,
      data: packetBytes,
      mtu: mtu,
      isCompressedData: transferType == BlastQrCompression.gzip,
    );
  }

  static bool bytesIsValidBlastQrCode(Uint8List? bytes) {
    if (bytes == null || bytes.length < headerLength) {
      return false;
    }
    return bytes[0] == signatureBytes[0] &&
        bytes[1] == signatureBytes[1] &&
        bytes[2] == signatureBytes[2];
  }
}
