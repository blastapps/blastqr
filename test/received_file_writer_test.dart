import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:blast_qr/features/scan/received_file_writer.dart';
import 'package:blast_qr/model/blast_qrcode_data.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _transferObject(String name, List<int> content) {
  final nameBlock = Uint8List(BlastQrcodeData.nameBlockLength)
    ..setAll(0, utf8.encode(name));
  return Uint8List.fromList([...nameBlock, ...content]);
}

void main() {
  late Directory dir;
  late String outputPath;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('received_file_writer_test');
    outputPath = '${dir.path}/out';
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('writes uncompressed content and returns the name block', () async {
    final content = List.generate(5000, (i) => i % 251);
    final nameBlock = await writeReceivedFile(
      data: _transferObject('a.bin', content),
      gzipped: false,
      outputPath: outputPath,
    );

    expect(utf8.decode(nameBlock).replaceAll('\x00', ''), 'a.bin');
    expect(File(outputPath).readAsBytesSync(), content);
  });

  test('decompresses gzip content to disk', () async {
    final content = utf8.encode('hello ' * 100000);
    final nameBlock = await writeReceivedFile(
      data: Uint8List.fromList(
        gzip.encode(_transferObject('hello.txt', content)),
      ),
      gzipped: true,
      outputPath: outputPath,
    );

    expect(utf8.decode(nameBlock).replaceAll('\x00', ''), 'hello.txt');
    expect(File(outputPath).readAsBytesSync(), content);
  });

  test('rejects data shorter than the name block', () async {
    await expectLater(
      writeReceivedFile(
        data: Uint8List(10),
        gzipped: false,
        outputPath: outputPath,
      ),
      throwsA(isA<FormatException>()),
    );
    expect(File(outputPath).existsSync(), isFalse);
  });

  test('rejects corrupt gzip and removes the partial file', () async {
    final valid = gzip.encode(_transferObject('x', List.filled(10000, 7)));
    final corrupt = Uint8List.fromList(valid.sublist(0, valid.length ~/ 2));

    await expectLater(
      writeReceivedFile(data: corrupt, gzipped: true, outputPath: outputPath),
      throwsA(anything),
    );
    expect(File(outputPath).existsSync(), isFalse);
  });

  test('stops a gzip bomb at the size limit', () async {
    // 50 MB of zeros compresses to ~50 KB.
    final bomb = gzip.encode(_transferObject('bomb', Uint8List(50 << 20)));

    await expectLater(
      writeReceivedFile(
        data: Uint8List.fromList(bomb),
        gzipped: true,
        outputPath: outputPath,
        maxContentBytes: 1 << 20,
      ),
      throwsA(isA<ReceivedFileTooLargeException>()),
    );
    expect(File(outputPath).existsSync(), isFalse);
  });
}
