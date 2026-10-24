import 'dart:convert';

import 'package:flutter/foundation.dart';

enum QrEncodingType { bytes, base45, base64 }

enum BlastQrCompression {
  none,
  gzip;

  static const _noneValue = 0x01;
  static const _gzipValue = 0x02;

  int get headerByte {
    switch (this) {
      case BlastQrCompression.none:
        return _noneValue;
      case BlastQrCompression.gzip:
        return _gzipValue;
    }
  }

  static BlastQrCompression fromByte(int byte) {
    return byte == _gzipValue
        ? BlastQrCompression.gzip
        : BlastQrCompression.none;
  }
}

class BlastQrcodeData {
  // "BQR" — 3-byte magic at offset 0 for fast frame identification
  static final signatureBytes = Uint8List.fromList([0x42, 0x51, 0x52]);
  static const int protocolVersion = 1;
  static final int headerLength = 13;

  /// Fixed-size filename block at the start of the transfer object.
  static const int nameBlockLength = 128;

  /// Largest file content we send or accept (~4 GB). Together with the name
  /// block it still fits the u32 `transferLength` header field.
  static const int maxFileBytes = 0xFFFFFFFF - nameBlockLength;

  /// RaptorQ packet id (source block number + symbol id) before each symbol.
  static const int packetIdLength = 4;

  /// Smallest symbol size a v1 sender produces (its MTU setting starts at
  /// 100). Below 64 RaptorQ switches alignment and our MTU inference breaks.
  static const int minSymbolSize = 64;

  /// Most symbols a transfer may have. The RaptorQ decoder reserves memory
  /// per symbol as soon as it's created, so this caps what one frame can make
  /// us allocate. Still allows ~4.3 GB at the default MTU.
  static const int maxSymbolCount = 1500000;

  /// Symbol size RaptorQ uses for a given MTU (rounded down to 8).
  static int symbolSizeForMtu(int mtu) => mtu - mtu % 8;

  /// Whether a transfer of [transferLength] bytes stays within
  /// [maxSymbolCount] at [symbolSize].
  static bool fitsSymbolLimit(int transferLength, int symbolSize) =>
      (transferLength / symbolSize).ceil() <= maxSymbolCount;

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
    int mtu = bytes.length - headerLength;

    final transferType = BlastQrCompression.fromByte(bytes[12]);
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

  /// RaptorQ symbol size carried by this frame.
  int get symbolSize => data.length - packetIdLength;

  /// Whether the header describes a transfer we can safely build a decoder
  /// for. Every frame from a real v1 sender passes; this only rejects values
  /// that would make the RaptorQ decoder over-allocate or crash.
  bool get isDecodable =>
      symbolSize >= minSymbolSize &&
      symbolSize % 8 == 0 &&
      transferLength >= nameBlockLength &&
      fitsSymbolLimit(transferLength, symbolSize);

  /// Values that stay the same for every frame of one transfer. Frames with a
  /// different key belong to another transfer.
  ({int transferLength, int symbolSize, bool isCompressed, String extension})
  get streamKey => (
    transferLength: transferLength,
    symbolSize: symbolSize,
    isCompressed: isCompressedData,
    extension: fileExtension,
  );

  static bool bytesIsValidBlastQrCode(Uint8List? bytes) {
    if (bytes == null || bytes.length < headerLength) {
      return false;
    }
    return bytes[0] == signatureBytes[0] &&
        bytes[1] == signatureBytes[1] &&
        bytes[2] == signatureBytes[2];
  }
}
