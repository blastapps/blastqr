import 'dart:async';
import 'dart:io';

import 'package:blast_qr/features/send/send_plan.dart';
import 'package:blast_qr/model/file_type.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:flutter_test/flutter_test.dart';

const _mb = 1000000;

FileWrapper _file(String name, int size) {
  final extension = name.split('.').last;
  return FileWrapper(
    file: File(name),
    type: FileType(
      extension: extension,
      mimeType: switch (extension) {
        'jpg' => 'image/jpeg',
        'png' => 'image/png',
        'gif' => 'image/gif',
        'pdf' => 'application/pdf',
        _ => 'application/zip',
      },
    ),
    size: size,
    modified: DateTime(2026),
  );
}

FileWrapper _jpg(int size) => _file('photo.jpg', size);
FileWrapper _pdf(int size) => _file('doc.pdf', size);

/// A zip step the test finishes by hand, recording what it was asked for.
class _FakeZip {
  _FakeZip(this.directory);

  final Directory directory;
  final calls = <bool>[];
  Completer<FileWrapper>? _pending;

  Future<FileWrapper> call({required bool compressImages}) {
    calls.add(compressImages);
    return (_pending = Completer()).future;
  }

  /// Finishes the zip with a bundle of [size] bytes on disk.
  Future<FileWrapper> finish(int size) async {
    final file = File('${directory.path}/bundle-${calls.length}.zip')
      ..writeAsStringSync('zip');
    final bundle = _file(file.path, size);
    _pending!.complete(bundle);
    await pumpEventQueue();
    return bundle;
  }
}

void main() {
  late Directory temp;
  late _FakeZip zip;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('send_plan_test');
    zip = _FakeZip(temp);
  });

  tearDown(() => temp.deleteSync(recursive: true));

  SendPlan plan(List<FileWrapper> files, {bool compress = false}) =>
      SendPlan(files, compressImages: compress, zip: zip.call);

  group('single file', () {
    test('a small file is sent as is, without a warning', () {
      final file = _jpg(1 * _mb);
      final p = plan([file]);

      expect(p.showsWarning, isFalse);
      expect(p.compressImages, isFalse);
      expect(p.file, file);
      expect(zip.calls, isEmpty);
    });

    test('a small image is compressed when asked', () {
      final p = plan([_jpg(1 * _mb)], compress: true);

      expect(p.showsWarning, isFalse);
      expect(p.compressImages, isTrue);
      expect(zip.calls, isEmpty);
    });

    test('an image under 400 KB is never compressed', () {
      final p = plan([_jpg(400000)], compress: true);

      expect(p.compressImages, isFalse);
    });

    test('a PNG is compressed', () {
      final p = plan([_file('shot.png', 3 * _mb)], compress: true);

      expect(p.showsWarning, isFalse);
      expect(p.compressImages, isTrue);
    });

    test('a GIF is never compressed', () {
      final p = plan([_file('anim.gif', 3 * _mb)], compress: true);

      expect(p.showsWarning, isTrue);
      expect(p.compressibleImages, 0);
      expect(p.compressImages, isFalse);
    });

    test('a large image warns and offers compressing', () {
      final p = plan([_jpg(3 * _mb)]);

      expect(p.showsWarning, isTrue);
      expect(p.compressibleImages, 1);
      expect(p.size, 3 * _mb);
    });

    test('compressing a large image is done while sending, not zipped', () {
      final p = plan([_jpg(3 * _mb)])..sendCompressed();

      expect(p.showsWarning, isFalse);
      expect(p.compressImages, isTrue);
      expect(zip.calls, isEmpty);
    });

    test('sending a large image as is keeps it uncompressed', () {
      final p = plan([_jpg(3 * _mb)])..sendAsIs();

      expect(p.showsWarning, isFalse);
      expect(p.compressImages, isFalse);
    });

    test('a large image is compressed without a warning when asked', () {
      final p = plan([_jpg(3 * _mb)], compress: true);

      expect(p.showsWarning, isFalse);
      expect(p.compressImages, isTrue);
    });

    test('a large non-image warns even when compressing', () {
      final p = plan([_pdf(3 * _mb)], compress: true);

      expect(p.showsWarning, isTrue);
      expect(p.compressibleImages, 0);
      expect(p.compressImages, isFalse);
    });
  });

  group('several files', () {
    test('a small bundle is zipped right away, without a warning', () async {
      final p = plan([_jpg(500000), _pdf(500000)]);

      expect(zip.calls, [false]);
      expect(p.isZipping, isTrue);
      expect(p.showsWarning, isFalse);
      expect(p.file, isNull);

      final bundle = await zip.finish(1 * _mb);

      expect(p.isZipping, isFalse);
      expect(p.file, bundle);
      expect(p.showsWarning, isFalse);
    });

    test('a large bundle without images warns once zipped', () async {
      final p = plan([_pdf(2 * _mb), _pdf(2 * _mb)]);

      expect(zip.calls, [false]);
      expect(p.showsWarning, isFalse);

      await zip.finish(4 * _mb);

      expect(p.showsWarning, isTrue);
      expect(p.compressibleImages, 0);
      expect(p.size, 4 * _mb);

      p.sendAsIs();

      expect(p.showsWarning, isFalse);
      expect(zip.calls, [false]);
    });

    test('images are offered for compressing before zipping', () {
      final p = plan([_jpg(3 * _mb), _jpg(2 * _mb), _jpg(1 * _mb), _pdf(10)]);

      expect(p.showsWarning, isTrue);
      expect(p.compressibleImages, 3);
      expect(p.size, 6 * _mb + 10);
      expect(zip.calls, isEmpty);
    });

    test('choosing to compress zips with compression', () async {
      final p = plan([_jpg(3 * _mb), _jpg(3 * _mb)])..sendCompressed();

      expect(zip.calls, [true]);
      expect(p.compressImages, isTrue);
      expect(p.showsWarning, isFalse);

      // Still large, but the user has already chosen.
      await zip.finish(2 * _mb);

      expect(p.showsWarning, isFalse);
      expect(p.size, 2 * _mb);
    });

    test('choosing to send as is zips without compression', () async {
      final p = plan([_jpg(3 * _mb), _jpg(3 * _mb)])..sendAsIs();

      expect(zip.calls, [false]);
      expect(p.compressImages, isFalse);

      await zip.finish(6 * _mb);

      expect(p.showsWarning, isFalse);
    });

    test('compressing zips right away without a warning', () {
      final p = plan([_jpg(3 * _mb), _jpg(3 * _mb)], compress: true);

      expect(zip.calls, [true]);
      expect(p.compressImages, isTrue);
      expect(p.showsWarning, isFalse);
    });

    test('compressing still warns if the bundle stays large', () async {
      final p = plan([_jpg(3 * _mb), _jpg(3 * _mb)], compress: true);

      await zip.finish(3 * _mb);

      expect(p.showsWarning, isTrue);
      expect(p.compressibleImages, 0);
    });

    test('compressing skips the warning if the bundle is small', () async {
      final p = plan([_jpg(3 * _mb), _jpg(3 * _mb)], compress: true);

      await zip.finish(1 * _mb);

      expect(p.showsWarning, isFalse);
    });

    test('small images in a bundle are compressed when asked', () {
      final p = plan([_jpg(500000), _pdf(500000)], compress: true);

      expect(zip.calls, [true]);
      expect(p.compressImages, isTrue);
    });

    test('images under 400 KB in a bundle are never compressed', () {
      final p = plan([_jpg(300000), _pdf(300000)], compress: true);

      expect(zip.calls, [false]);
      expect(p.compressImages, isFalse);
    });

    test('listeners hear when zipping finishes', () async {
      final p = plan([_pdf(10), _pdf(10)]);
      var notified = 0;
      p.addListener(() => notified++);

      await zip.finish(20);

      expect(notified, 1);
    });
  });

  group('cleanup', () {
    test('disposing deletes the bundle', () async {
      final p = plan([_pdf(10), _pdf(10)]);
      final bundle = await zip.finish(20);

      p.dispose();
      await pumpEventQueue();

      expect(bundle.file.existsSync(), isFalse);
    });

    test('a bundle zipped after disposing is deleted', () async {
      final p = plan([_pdf(10), _pdf(10)])..dispose();

      final bundle = await zip.finish(20);

      expect(bundle.file.existsSync(), isFalse);
      expect(p.file, isNull);
    });

    test('disposing never deletes a single file', () async {
      final original = File('${temp.path}/doc.pdf')..writeAsStringSync('x');
      plan([_file(original.path, 10)]).dispose();
      await pumpEventQueue();

      expect(original.existsSync(), isTrue);
    });
  });
}
