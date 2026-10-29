import 'dart:typed_data';

import 'package:blast_qr/features/scan/decode_stats.dart';
import 'package:flutter_test/flutter_test.dart';

/// A RaptorQ packet header: source block number, then the 24-bit symbol id.
Uint8List _packet(int id, {int block = 0}) =>
    Uint8List.fromList([block, id >> 16, (id >> 8) & 0xff, id & 0xff, 0]);

void main() {
  final stats = DecodeStats.instance;
  setUp(stats.clear);

  test('codes shown span from the first id caught to the last', () {
    stats.startTransfer(1000);
    for (final id in [10, 11, 13, 14, 12, 11, 15]) {
      stats.recordPacket(_packet(id));
    }
    final t = stats.transfers.single;
    expect(t.codesShown, 6);
    expect(t.codesCaught, 6);
  });

  test('near optimal once complete with 90% of the codes caught', () {
    stats.startTransfer(1000);
    // 40 shown, 4 missed.
    for (var id = 100; id < 140; id++) {
      if (id % 10 != 5) stats.recordPacket(_packet(id));
    }
    final t = stats.transfers.single;
    expect(t.nearOptimal, isFalse, reason: 'not complete yet');
    stats.completeTransfer();
    expect(t.codesShown, 40);
    expect(t.codesCaught, 36);
    expect(t.nearOptimal, isTrue);
  });

  test('not near optimal when more than 10% of the codes were missed', () {
    stats.startTransfer(1000);
    for (var id = 0; id < 40; id += 2) {
      stats.recordPacket(_packet(id));
    }
    stats.completeTransfer();
    expect(stats.transfers.single.nearOptimal, isFalse);
  });

  test('unknown for transfers split into several blocks', () {
    stats.startTransfer(1000);
    stats.recordPacket(_packet(5));
    stats.recordPacket(_packet(5, block: 1));
    stats.completeTransfer();
    final t = stats.transfers.single;
    expect(t.codesShown, isNull);
    expect(t.nearOptimal, isFalse);
  });
}
