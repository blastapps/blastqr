import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:blast_qr/features/scan/received_file_writer.dart';
import 'package:blast_qr/model/blast_qrcode_data.dart';
import 'package:blast_qr/model/transfer_container.dart';
import 'package:flutter_test/flutter_test.dart';

/// v2 transfer object: metadata block + content.
Uint8List _v2Object(String name, List<int> content) => Uint8List.fromList([
  ...TransferContainer.encodeMetadata(fileName: name),
  ...content,
]);

void main() {
  late Directory dir;
  late String outputPath;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('received_file_writer_test');
    outputPath = '${dir.path}/out';
  });

  tearDown(() => dir.deleteSync(recursive: true));

  Future<TransferMetadata> write(
    Uint8List data, {
    bool gzipped = false,
    int maxContentBytes = BlastQrcodeData.maxFileBytes,
  }) => writeReceivedFile(
    data: data,
    gzipped: gzipped,
    outputPath: outputPath,
    maxContentBytes: maxContentBytes,
  );

  group('container', () {
    test('writes the content and returns the filename', () async {
      final content = List.generate(5000, (i) => i % 251);
      final metadata = await write(_v2Object('a.bin', content));

      expect(metadata.fileName, 'a.bin');
      expect(File(outputPath).readAsBytesSync(), content);
    });

    test('decompresses gzip content to disk', () async {
      final content = utf8.encode('hello ' * 100000);
      final metadata = await write(
        Uint8List.fromList(gzip.encode(_v2Object('hello.txt', content))),
        gzipped: true,
      );

      expect(metadata.fileName, 'hello.txt');
      expect(File(outputPath).readAsBytesSync(), content);
    });

    test('handles an empty file', () async {
      final metadata = await write(_v2Object('empty.txt', []));
      expect(metadata.fileName, 'empty.txt');
      expect(File(outputPath).readAsBytesSync(), isEmpty);
    });

    test('rejects data shorter than its metadata', () async {
      final full = _v2Object('name.txt', []);
      await expectLater(
        write(full.sublist(0, full.length - 2)),
        throwsA(isA<FormatException>()),
      );
      expect(File(outputPath).existsSync(), isFalse);
    });
  });

  test('rejects corrupt gzip and removes the partial file', () async {
    final valid = gzip.encode(_v2Object('x', List.filled(10000, 7)));
    final corrupt = Uint8List.fromList(valid.sublist(0, valid.length ~/ 2));

    await expectLater(write(corrupt, gzipped: true), throwsA(anything));
    expect(File(outputPath).existsSync(), isFalse);
  });

  test('stops a gzip bomb at the size limit', () async {
    // 50 MB of zeros compresses to ~50 KB.
    final bomb = gzip.encode(_v2Object('bomb', Uint8List(50 << 20)));

    await expectLater(
      write(Uint8List.fromList(bomb), gzipped: true, maxContentBytes: 1 << 20),
      throwsA(isA<ReceivedFileTooLargeException>()),
    );
    expect(File(outputPath).existsSync(), isFalse);
  });
}
