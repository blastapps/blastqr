import 'dart:typed_data';

import 'package:blast_qr/model/blast_qrcode_data.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a frame the way the v1 sender does (see file_qr_encoder.dart).
BlastQrcodeData _frame({
  required int transferLength,
  required int symbolSize,
  String ext = 'jpg',
  bool gzip = false,
  int sourceBlock = 0,
}) {
  final bytes = Uint8List(
    BlastQrcodeData.headerLength + BlastQrcodeData.packetIdLength + symbolSize,
  );
  bytes.setAll(0, BlastQrcodeData.signatureBytes);
  bytes[3] = BlastQrcodeData.protocolVersion;
  bytes.buffer.asByteData().setUint32(4, transferLength, Endian.big);
  bytes.setAll(8, ext.codeUnits);
  bytes[12] =
      (gzip ? BlastQrCompression.gzip : BlastQrCompression.none).headerByte;
  bytes[13] = sourceBlock;
  return BlastQrcodeData.fromBytes(bytes);
}

void main() {
  group('isDecodable', () {
    test('accepts frames from any v1 MTU setting', () {
      // The send settings allow MTUs from 100 to 2935.
      for (final mtu in [100, 500, 1000, 2000, 2935]) {
        final symbolSize = BlastQrcodeData.symbolSizeForMtu(mtu);
        final frame = _frame(transferLength: 50000, symbolSize: symbolSize);
        expect(frame.symbolSize, symbolSize);
        expect(frame.isDecodable, isTrue, reason: 'mtu $mtu');
      }
    });

    test('accepts a ~4 GB transfer at the default MTU', () {
      final frame = _frame(
        transferLength: BlastQrcodeData.maxFileBytes,
        symbolSize: BlastQrcodeData.symbolSizeForMtu(2935),
      );
      expect(frame.isDecodable, isTrue);
    });

    test('accepts an empty file (just the name block)', () {
      final frame = _frame(
        transferLength: BlastQrcodeData.nameBlockLength,
        symbolSize: 96,
      );
      expect(frame.isDecodable, isTrue);
    });

    test('rejects a huge transfer with tiny symbols', () {
      // ~45M symbols: would make the decoder reserve ~1 GB.
      final frame = _frame(transferLength: 0xFFFFFFFF, symbolSize: 96);
      expect(frame.isDecodable, isFalse);
    });

    test('rejects zero or too-short transfer length', () {
      expect(_frame(transferLength: 0, symbolSize: 96).isDecodable, isFalse);
      expect(_frame(transferLength: 127, symbolSize: 96).isDecodable, isFalse);
    });

    test('rejects symbol sizes no v1 sender produces', () {
      expect(_frame(transferLength: 5000, symbolSize: 56).isDecodable, isFalse);
      expect(
        _frame(transferLength: 5000, symbolSize: 101).isDecodable,
        isFalse,
      );
    });
  });

  group('streamKey', () {
    test('is equal for frames of the same transfer', () {
      final a = _frame(transferLength: 9000, symbolSize: 2928, sourceBlock: 0);
      final b = _frame(transferLength: 9000, symbolSize: 2928, sourceBlock: 1);
      expect(a.streamKey, b.streamKey);
    });

    test('differs when any fixed field differs', () {
      final base = _frame(transferLength: 9000, symbolSize: 2928);
      expect(
        _frame(transferLength: 9001, symbolSize: 2928).streamKey,
        isNot(base.streamKey),
      );
      expect(
        _frame(transferLength: 9000, symbolSize: 1000).streamKey,
        isNot(base.streamKey),
      );
      expect(
        _frame(transferLength: 9000, symbolSize: 2928, gzip: true).streamKey,
        isNot(base.streamKey),
      );
      expect(
        _frame(transferLength: 9000, symbolSize: 2928, ext: 'png').streamKey,
        isNot(base.streamKey),
      );
    });
  });

  test('sender and receiver limits agree', () {
    // A file the sender allows must produce frames the receiver accepts.
    for (final mtu in [100, 1000, 2935]) {
      final symbolSize = BlastQrcodeData.symbolSizeForMtu(mtu);
      final maxTransfer = BlastQrcodeData.maxSymbolCount * symbolSize;
      expect(
        BlastQrcodeData.fitsSymbolLimit(maxTransfer, symbolSize),
        isTrue,
      );
      expect(
        BlastQrcodeData.fitsSymbolLimit(maxTransfer + 1, symbolSize),
        isFalse,
      );
    }
  });
}
