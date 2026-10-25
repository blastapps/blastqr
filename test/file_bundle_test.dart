import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:blast_qr/file_bundle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late Directory out;

  setUp(() {
    root = Directory.systemTemp.createTempSync('file_bundle_test');
    out = Directory('${root.path}/out')..createSync();
  });

  tearDown(() => root.deleteSync(recursive: true));

  Uint8List bytes(String text) => Uint8List.fromList(utf8.encode(text));

  List<String> names(List<String> paths) =>
      paths.map((p) => p.split(Platform.pathSeparator).last).toList();

  test('files round trip through a bundle', () async {
    final onDisk = File('${root.path}/b.txt')..writeAsStringSync('from disk');
    final zip = '${root.path}/bundle.zip';
    await writeBundle([
      (name: 'a.txt', path: null, bytes: bytes('in memory')),
      (name: 'b.txt', path: onDisk.path, bytes: null),
    ], zip);

    final paths = await extractBundle(zip, out);

    expect(names(paths), ['a.txt', 'b.txt']);
    expect(File(paths[0]).readAsStringSync(), 'in memory');
    expect(File(paths[1]).readAsStringSync(), 'from disk');
  });

  test('duplicate names in a bundle are made unique', () async {
    final zip = '${root.path}/bundle.zip';
    await writeBundle([
      (name: 'same.txt', path: null, bytes: bytes('one')),
      (name: 'same.txt', path: null, bytes: bytes('two')),
    ], zip);

    final paths = await extractBundle(zip, out);

    expect(names(paths), ['same.txt', 'same(1).txt']);
  });

  test('extracted names never leave the folder or replace files', () async {
    File('${out.path}/taken.txt').writeAsStringSync('keep me');
    final archive = Archive()
      ..add(
        ArchiveFile.bytes('../../escape.txt', bytes('x'))
          ..compression = CompressionType.none,
      )
      ..add(
        ArchiveFile.bytes('dir/taken.txt', bytes('y'))
          ..compression = CompressionType.none,
      );
    final zip = File('${root.path}/crafted.zip')
      ..writeAsBytesSync(ZipEncoder().encodeBytes(archive));

    final paths = await extractBundle(zip.path, out);

    expect(names(paths), ['escape.txt', 'taken(1).txt']);
    expect(paths.every((p) => File(p).parent.path == out.path), isTrue);
    expect(File('${out.path}/taken.txt').readAsStringSync(), 'keep me');
  });

  test('compressed entries are refused', () async {
    final archive = Archive()
      ..add(ArchiveFile.bytes('big.txt', bytes('a' * 10000)));
    final zip = File('${root.path}/deflated.zip')
      ..writeAsBytesSync(ZipEncoder().encodeBytes(archive));

    await expectLater(
      extractBundle(zip.path, out),
      throwsA(isA<BundleFormatException>()),
    );
    expect(out.listSync(), isEmpty);
  });

  test('data that is not a zip is refused', () async {
    final zip = File('${root.path}/junk.zip')..writeAsStringSync('not a zip');

    await expectLater(
      extractBundle(zip.path, out),
      throwsA(isA<BundleFormatException>()),
    );
    expect(out.listSync(), isEmpty);
  });
}
