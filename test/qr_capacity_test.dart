import 'dart:typed_data';

import 'package:blast_qr/features/send/helpers/file_qr_encoder.dart';
import 'package:blast_qr/features/send/helpers/qr_lookup_table.dart';
import 'package:blast_qr/model/blast_qrcode_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr/qr.dart';

/// Smallest and largest MTU the send settings allow.
const _minMtu = 100;
const _maxMtu = 2935;

/// Bytes in one frame at [mtu]: header + packet id + symbol.
int _frameLength(int mtu) =>
    BlastQrcodeData.headerLength +
    BlastQrcodeData.packetIdLength +
    BlastQrcodeData.symbolSizeForMtu(mtu);

void main() {
  test('every MTU setting fits the QR version picked for it', () {
    for (var mtu = _minMtu; mtu <= _maxMtu; mtu++) {
      final version = FileQrEncoder.pickQrVersion(mtu);
      expect(
        _frameLength(mtu),
        lessThanOrEqualTo(qrByteCapacityL[version]!),
        reason: 'MTU $mtu → QR version $version',
      );
    }
  });

  test('the qr package rejects data over capacity (so the test below means something)', () {
    final tooBig = Uint8List(qrByteCapacityL[40]! + 1);
    final qrCode = QrCode(40, QrErrorCorrectLevel.L)
      ..addByteData(tooBig.buffer.asByteData());
    expect(() => QrImage.withMaskPattern(qrCode, 3), throwsA(anything));
  });

  test('the qr package can render the largest frame of every version used', () {
    // Largest frame per QR version, so the capacity table is checked against
    // the real encoder rather than trusted.
    final largest = <int, int>{};
    for (var mtu = _minMtu; mtu <= _maxMtu; mtu++) {
      final version = FileQrEncoder.pickQrVersion(mtu);
      final length = _frameLength(mtu);
      if (length > (largest[version] ?? 0)) largest[version] = length;
    }

    for (final MapEntry(key: version, value: length) in largest.entries) {
      final bytes = Uint8List(length);
      for (var i = 0; i < length; i++) {
        bytes[i] = (i * 37 + 11) & 0xFF;
      }
      final qrCode = QrCode(version, QrErrorCorrectLevel.L)
        ..addByteData(bytes.buffer.asByteData());
      expect(
        () => QrImage.withMaskPattern(qrCode, 3),
        returnsNormally,
        reason: '$length bytes in QR version $version',
      );
    }
  });
}
