// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:typed_data';

import 'package:base45/base45.dart';
import 'package:flutter/foundation.dart';

enum QrEncodingType { bytes, base45, base64 }

class BlastQrcodeData {
  final int transferLength;
  final Uint8List data;

  BlastQrcodeData({required this.transferLength, required this.data});

  factory BlastQrcodeData.fromString(String stringData) {
    final comps = stringData.split('|');
    final headerComps = comps[0].split('/');
    final len = int.parse(headerComps[0]);
    final qrEncoding = QrEncodingType.values[int.parse(headerComps[1])];
    final data = comps[1];
    final decodeMethod =
        qrEncoding == QrEncodingType.base64 ? base64Decode : Base45.decode;
    final bytes = decodeMethod(data);
    return BlastQrcodeData(transferLength: len, data: bytes);
  }

  factory BlastQrcodeData.fromBytes(Uint8List bytes) {
    ByteData byteData = bytes.buffer.asByteData(0, 8);
    int extractedSize = byteData.getUint64(0, Endian.big);
    Uint8List packetBytes = bytes.sublist(8);
    return BlastQrcodeData(transferLength: extractedSize, data: packetBytes);
  }
}

extension QrEncodingTypeExt on QrEncodingType {
  int get mtu {
    switch (this) {
      case QrEncodingType.bytes:
        return 924;
      case QrEncodingType.base45:
        return 820;
      case QrEncodingType.base64:
        return 700;
    }
  }
}
