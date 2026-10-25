import 'dart:typed_data';

import 'package:blast_qr/model/blast_qrcode_data.dart';
import 'package:flutter_test/flutter_test.dart';

/// A v2 frame as the sender builds it.
Uint8List _v2Bytes({
  int flags = 0,
  int kind = BlastQrcodeData.kindFile,
  int sessionId = 0x1234,
  int transferLength = 50000,
  int symbolSize = 2928,
  int? packetLength,
  int sourceBlock = 0,
}) {
  final header = BlastQrcodeData.buildHeader(
    flags: flags,
    kind: kind,
    sessionId: sessionId,
    transferLength: transferLength,
    symbolSize: symbolSize,
  );
  final packet = Uint8List(
    packetLength ?? BlastQrcodeData.packetIdLength + symbolSize,
  )..[0] = sourceBlock;
  return Uint8List.fromList([...header, ...packet]);
}

BlastQrcodeData _v2({
  int flags = 0,
  int sessionId = 0x1234,
  int transferLength = 50000,
  int symbolSize = 2928,
  int sourceBlock = 0,
}) {
  final parsed = BlastQrcodeData.parse(
    _v2Bytes(
      flags: flags,
      sessionId: sessionId,
      transferLength: transferLength,
      symbolSize: symbolSize,
      sourceBlock: sourceBlock,
    ),
  );
  expect(parsed.verdict, FrameVerdict.ok);
  return parsed.frame!;
}

void main() {
  group('v2 header', () {
    test('exact bytes (wire format, change only on purpose)', () {
      final header = BlastQrcodeData.buildHeader(
        flags: BlastQrcodeData.flagGzip,
        kind: 3,
        sessionId: 0xBEEF,
        transferLength: 0x01020304,
        symbolSize: 2928,
      );
      expect(header, [
        0x62, 0x51, 0x52, // "bQR"
        0x02, // version
        0x01, // flags: gzip
        0x03, // kind
        0xBE, 0xEF, // sessionId
        0x01, 0x02, 0x03, 0x04, // transferLength
        0x0B, 0x70, // symbolSize 2928
      ]);
    });

    test('round-trips through parse', () {
      final frame = _v2(
        flags: BlastQrcodeData.flagGzip,
        sessionId: 0xBEEF,
        transferLength: 123456,
        symbolSize: 1000,
      );
      expect(frame.isCompressedData, isTrue);
      expect(frame.sessionId, 0xBEEF);
      expect(frame.transferLength, 123456);
      expect(frame.symbolSize, 1000);
      expect(frame.data.length, BlastQrcodeData.packetIdLength + 1000);
    });
  });

  group('verdicts', () {
    test('other QR codes are foreign', () {
      expect(BlastQrcodeData.parse(null).verdict, FrameVerdict.foreign);
      expect(
        BlastQrcodeData.parse(
          Uint8List.fromList('https://x.y'.codeUnits),
        ).verdict,
        FrameVerdict.foreign,
      );
    });

    test('newer versions ask for an update', () {
      final bytes = _v2Bytes()..[3] = 3;
      expect(BlastQrcodeData.parse(bytes).verdict, FrameVerdict.newerVersion);
    });

    test('unknown must-understand flags ask for an update', () {
      final bytes = _v2Bytes(flags: 0x04);
      expect(
        BlastQrcodeData.parse(bytes).verdict,
        FrameVerdict.unsupportedFlags,
      );
    });

    test('encrypted frames are accepted', () {
      final frame = _v2(
        flags: BlastQrcodeData.flagEncrypted | BlastQrcodeData.flagGzip,
      );
      expect(frame.isEncrypted, isTrue);
      expect(frame.isCompressedData, isTrue);
      expect(_v2().isEncrypted, isFalse);
    });

    test('unknown optional flags are ignored', () {
      final frame = _v2(flags: 0x10 | BlastQrcodeData.flagGzip);
      expect(frame.isCompressedData, isTrue);
    });

    test('frame length must match the declared symbol size', () {
      final bytes = _v2Bytes(symbolSize: 1000, packetLength: 900);
      expect(BlastQrcodeData.parse(bytes).verdict, FrameVerdict.malformed);
    });

    test('older versions (and 0) are malformed', () {
      expect(
        BlastQrcodeData.parse(_v2Bytes()..[3] = 0).verdict,
        FrameVerdict.malformed,
      );
      expect(
        BlastQrcodeData.parse(_v2Bytes()..[3] = 1).verdict,
        FrameVerdict.malformed,
      );
    });
  });

  group('isDecodable', () {
    test('accepts frames from any MTU setting', () {
      for (final mtu in [100, 500, 1000, 2000, 2935]) {
        final symbolSize = BlastQrcodeData.symbolSizeForMtu(mtu);
        expect(_v2(symbolSize: symbolSize).isDecodable, isTrue, reason: '$mtu');
      }
    });

    test('accepts a ~4 GB transfer at the default MTU', () {
      final frame = _v2(
        transferLength: BlastQrcodeData.maxFileBytes,
        symbolSize: 2928,
      );
      expect(frame.isDecodable, isTrue);
    });

    test('rejects a huge transfer with tiny symbols', () {
      // ~45M symbols: would make the decoder reserve ~1 GB.
      final frame = _v2(transferLength: 0xFFFFFFFF, symbolSize: 96);
      expect(frame.isDecodable, isFalse);
    });

    test('rejects empty transfers', () {
      expect(_v2(transferLength: 0).isDecodable, isFalse);
      expect(_v2(transferLength: 1).isDecodable, isFalse);
      expect(_v2(transferLength: 2).isDecodable, isTrue);
    });

    test('rejects symbol sizes no sender produces', () {
      expect(_v2(symbolSize: 56).isDecodable, isFalse);
      expect(_v2(symbolSize: 101).isDecodable, isFalse);
    });
  });

  group('streamKey', () {
    test('is equal for frames of the same transfer', () {
      expect(_v2(sourceBlock: 0).streamKey, _v2(sourceBlock: 1).streamKey);
    });

    test('differs for another session, even with identical settings', () {
      expect(_v2(sessionId: 1).streamKey, isNot(_v2(sessionId: 2).streamKey));
    });

    test('differs when any fixed field differs', () {
      final base = _v2();
      expect(_v2(transferLength: 50001).streamKey, isNot(base.streamKey));
      expect(_v2(symbolSize: 1000).streamKey, isNot(base.streamKey));
      expect(
        _v2(flags: BlastQrcodeData.flagGzip).streamKey,
        isNot(base.streamKey),
      );
    });
  });

  test('sender and receiver limits agree', () {
    for (final mtu in [100, 1000, 2935]) {
      final symbolSize = BlastQrcodeData.symbolSizeForMtu(mtu);
      final maxTransfer = BlastQrcodeData.maxSymbolCount * symbolSize;
      expect(BlastQrcodeData.fitsSymbolLimit(maxTransfer, symbolSize), isTrue);
      expect(
        BlastQrcodeData.fitsSymbolLimit(maxTransfer + 1, symbolSize),
        isFalse,
      );
    }
  });
}
