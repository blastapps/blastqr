import 'dart:convert';

import 'package:flutter/foundation.dart';

enum QrEncodingType { bytes, base45, base64 }

class BlastQrcodeData {
  static final signatureBytes = Uint8List.fromList([81, 45]);
  static final reserved = Uint8List.fromList([0, 1]);
  static final int headerLength = 16;

  final int transferLength;
  final String fileExtension;
  final Uint8List data;
  final int mtu;

  BlastQrcodeData({
    required this.transferLength,
    required this.fileExtension,
    required this.data,
    required this.mtu,
  });

  factory BlastQrcodeData.fromBytes(Uint8List bytes) {
    if (!bytesIsValidBlastQrCode(bytes)) {
      throw Exception('Not a valid BlastQR code.');
    }
    ByteData sizeByteData = bytes.buffer.asByteData(0, 4);
    Uint8List extBytes = bytes.sublist(4, 12);
    int fileSize = sizeByteData.getUint32(0, Endian.big);
    int mtu = bytes.length - headerLength;

    String ext = utf8
        .decode(extBytes, allowMalformed: false)
        .replaceAll('\x00', '');
    Uint8List packetBytes = bytes.sublist(headerLength);
    return BlastQrcodeData(
      transferLength: fileSize,
      fileExtension: ext,
      data: packetBytes,
      mtu: mtu,
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
