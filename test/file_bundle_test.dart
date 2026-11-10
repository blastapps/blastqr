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

  /// A zip whose [count] entries overlap: each entry's local header is
  /// followed by the next entry's header, down to [data] at the end, so every
  /// entry's content includes all the ones after it. Each entry claims
  /// [claimedSize] as its uncompressed size.
  Uint8List overlappingZip(Uint8List data, int count, {int? claimedSize}) {
    final b = BytesBuilder();
    void u16(int v) => b.add([v & 0xFF, v >> 8 & 0xFF]);
    void u32(int v) => b.add([for (var i = 0; i < 32; i += 8) v >> i & 0xFF]);

    // Entry i starts at offsets[i] and runs to the end of [data].
    final names = [for (var i = 0; i < count; i++) utf8.encode('f$i')];
    final offsets = <int>[];
    final sizes = <int>[];
    var remaining = data.length;
    for (var i = count - 1; i >= 0; i--) {
      sizes.insert(0, remaining);
      remaining += 30 + names[i].length;
    }
    for (var i = 0; i < count; i++) {
      offsets.add(b.length);
      u32(0x04034b50);
      for (final v in [20, 0, 0, 0, 0]) {
        u16(v);
      }
      u32(0);
      u32(sizes[i]);
      u32(sizes[i]);
      u16(names[i].length);
      u16(0);
      b.add(names[i]);
    }
    b.add(data);

    final cdOffset = b.length;
    for (var i = 0; i < count; i++) {
      u32(0x02014b50);
      for (final v in [20, 20, 0, 0, 0, 0]) {
        u16(v);
      }
      u32(0);
      u32(sizes[i]);
      u32(claimedSize ?? sizes[i]);
      for (final v in [names[i].length, 0, 0, 0, 0]) {
        u16(v);
      }
      u32(0);
      u32(offsets[i]);
      b.add(names[i]);
    }
    final cdSize = b.length - cdOffset;

    u32(0x06054b50);
    for (final v in [0, 0, count, count]) {
      u16(v);
    }
    u32(cdSize);
    u32(cdOffset);
    u16(0);
    return b.toBytes();
  }

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

  test('entries sharing data can\'t expand past the zip size', () async {
    final zip = File('${root.path}/overlap.zip')
      ..writeAsBytesSync(overlappingZip(bytes('x' * 1000), 20));

    await expectLater(
      extractBundle(zip.path, out),
      throwsA(isA<BundleFormatException>()),
    );
    expect(out.listSync(), isEmpty);
  });

  test('entries hiding their size can\'t expand past the zip size', () async {
    final zip = File('${root.path}/overlap.zip')
      ..writeAsBytesSync(overlappingZip(bytes('x' * 1000), 20, claimedSize: 0));

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
