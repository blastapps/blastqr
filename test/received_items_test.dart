import 'dart:io';

import 'package:blast_qr/features/files_received/received_items.dart';
import 'package:blast_qr/model/scanned_qr_code.dart';
import 'package:flutter_test/flutter_test.dart';

ReceivedQrCode _item(DateTime date) =>
    ReceivedQrCode(ScannedQrCode(file: File('x.txt'), text: '', scanned: date));

void main() {
  final now = DateTime(2026, 10, 30, 12);

  test('groups items under one header per day', () {
    final a = _item(DateTime(2026, 10, 30, 9));
    final b = _item(DateTime(2026, 10, 30, 8));
    final c = _item(DateTime(2026, 10, 29, 20));

    final rows = groupByDay([a, b, c], now: now);

    expect(rows.length, 5);
    expect((rows[0] as DateHeader).date, DateTime(2026, 10, 30));
    expect(rows.sublist(1, 3), [a, b]);
    expect((rows[3] as DateHeader).date, DateTime(2026, 10, 29));
    expect(rows[4], c);
  });

  test('puts items two or more years old under one older header', () {
    final recent = _item(DateTime(2026, 1, 1));
    final old1 = _item(DateTime(2024, 1, 1));
    final old2 = _item(DateTime(2020, 5, 5));

    final rows = groupByDay([recent, old1, old2], now: now);

    expect(rows.length, 5);
    expect((rows[2] as DateHeader).isOlder, isTrue);
    expect(rows.sublist(3), [old1, old2]);
  });

  test('returns nothing for no items', () {
    expect(groupByDay([], now: now), isEmpty);
  });
}
