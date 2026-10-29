import 'dart:io';

import 'package:blast_qr/model/scanned_qr_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('qr_codes_test');
  });

  tearDown(() async {
    await dir.delete(recursive: true);
  });

  test('loads nothing from a missing directory', () async {
    expect(await loadScannedQrCodes(Directory('${dir.path}/missing')), isEmpty);
  });

  test('round-trips text, newest first', () async {
    final sub = Directory('${dir.path}/qr_codes');
    final older = await saveScannedQrCode('https://example.com', sub);
    await older.file.setLastModified(DateTime(2024, 1, 1));
    await saveScannedQrCode('사진\nline two ✓', sub);

    final codes = await loadScannedQrCodes(sub);
    expect(codes.map((c) => c.text), ['사진\nline two ✓', 'https://example.com']);
    expect(codes.last.scanned, DateTime(2024, 1, 1));
  });
}
