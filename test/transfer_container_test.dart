import 'dart:convert';
import 'dart:typed_data';

import 'package:blast_qr/model/transfer_container.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exact bytes (wire format, change only on purpose)', () {
    expect(TransferContainer.encodeMetadata(fileName: 'a.jpg'), [
      0x00, 0x08, // metadata length: 8
      0x01, // tag: filename
      0x00, 0x05, // length: 5
      ...'a.jpg'.codeUnits,
    ]);
  });

  test('round-trips a filename', () {
    final block = TransferContainer.encodeMetadata(fileName: '사진 01.png');
    final metadata = TransferContainer.decodeMetadata(block.sublist(2));
    expect(metadata.fileName, '사진 01.png');
  });

  test('skips unknown tags, so newer senders can add metadata', () {
    final block = Uint8List.fromList([
      0x63, 0x00, 0x03, 1, 2, 3, // unknown tag 0x63
      0x01, 0x00, 0x05, ...'a.txt'.codeUnits,
    ]);
    expect(TransferContainer.decodeMetadata(block).fileName, 'a.txt');
  });

  test('rejects an entry that runs past the end', () {
    final block = Uint8List.fromList([0x01, 0x00, 0x09, ...'a.txt'.codeUnits]);
    expect(
      () => TransferContainer.decodeMetadata(block),
      throwsFormatException,
    );
  });

  test('shortens long names without splitting characters', () {
    final block = TransferContainer.encodeMetadata(fileName: '한' * 200);
    final name = TransferContainer.decodeMetadata(block.sublist(2)).fileName!;
    expect(
      utf8.encode(name).length,
      lessThanOrEqualTo(TransferContainer.maxFileNameBytes),
    );
    expect(name, '한' * 85); // 85 × 3 bytes = 255
  });

  test('bundle tag: exact bytes and round trip', () {
    final block = TransferContainer.encodeMetadata(
      fileName: 'a.zip',
      isBundle: true,
    );
    expect(block, [0, 11, 1, 0, 5, 0x61, 0x2E, 0x7A, 0x69, 0x70, 2, 0, 0]);

    final metadata = TransferContainer.decodeMetadata(block.sublist(2));
    expect(metadata.fileName, 'a.zip');
    expect(metadata.isBundle, isTrue);
    expect(
      TransferContainer.decodeMetadata(
        TransferContainer.encodeMetadata(fileName: 'a.zip').sublist(2),
      ).isBundle,
      isFalse,
    );
  });
}
