// Sends files through the real sender and receiver code, minus the camera:
// sender payload + header → RaptorQ stream → frame bytes → receiver's
// tracker, decoder, decryption and file saving. Uses the RaptorQ and crypto
// libraries, which `flutter test` builds for this machine.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:blast_qr/crypto/transfer_crypto.dart';
import 'package:blast_qr/file_bundle.dart';
import 'package:blast_qr/features/scan/received_file_writer.dart';
import 'package:blast_qr/features/scan/transfer_tracker.dart';
import 'package:blast_qr/features/send/helpers/file_qr_encoder.dart';
import 'package:blast_qr/features/send/prepare_transfer.dart';
import 'package:blast_qr/model/blast_qrcode_data.dart';
import 'package:blast_qr/raptorq/raptorq_decoder.dart';
import 'package:blast_qr/raptorq/raptorq_streaming_encoder.dart';
import 'package:blastqr_crypto/blastqr_crypto.dart'
    show BlastqrCrypto, envelopeOverhead;
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raptorq_flutter/src/rust/frb_generated.dart';

import 'native_library.dart';

final _libraryPath = nativeLibraryPath('raptorq_flutter');

final _cryptoLibraryPath = nativeLibraryPath('rust_lib_blastqr_crypto');

final _skip =
    File(_libraryPath).existsSync() && File(_cryptoLibraryPath).existsSync()
    ? false
    : 'RaptorQ or crypto library not built (see top of file)';

/// Bytes that don't compress (so gzip is dropped).
Uint8List _random(int length, {int seed = 1}) {
  final random = Random(seed);
  return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
}

void main() {
  late Directory docs;
  late Directory temp;

  setUpAll(() async {
    if (_skip != false) return;
    await RustLib.init(externalLibrary: ExternalLibrary.open(_libraryPath));
    await BlastqrCrypto.init(
      externalLibrary: ExternalLibrary.open(_cryptoLibraryPath),
    );
  });

  setUp(() {
    final root = Directory.systemTemp.createTempSync('round_trip_test');
    docs = Directory('${root.path}/docs')..createSync();
    temp = Directory('${root.path}/tmp')..createSync();
  });

  tearDown(() => docs.parent.deleteSync(recursive: true));

  /// Sends [content] as [fileName] and returns the received file. The
  /// receiver catches each frame with probability [catchRate]. With a
  /// [password] the transfer is encrypted, and the receiver tries
  /// [receiverPasswords] in order (all on the same received data, like the
  /// app does), counting wrong ones in `wrongAttempts`. With [isBundle],
  /// [content] is a zip that the receiver extracts into `files`.
  Future<({File file, List<File> files, bool gzipped, int wrongAttempts})> send(
    String fileName,
    Uint8List content, {
    bool tryGzip = true,
    int mtu = 2935,
    double catchRate = 1,
    String? password,
    List<String>? receiverPasswords,
    bool isBundle = false,
  }) async {
    // Sender.
    final transfer = await buildTransferObject(
      fileName: fileName,
      content: content,
      tryGzip: tryGzip,
      password: password,
      isBundle: isBundle,
    );
    final encoder = RaptorqStreamingEncoder(mtu: mtu);
    await encoder.init(transfer.bytes);
    final header = buildFrameHeader(
      gzipped: transfer.gzipped,
      encrypted: password != null,
      transferLength: transfer.bytes.length,
      symbolSize: encoder.symbolSize,
    );

    // Receiver.
    final tracker = TransferTracker();
    Uint8List? result;
    final decoder = RaptorqDecoder(onReceiveResult: (r) => result = r);
    BlastQrcodeData? firstFrame;
    final random = Random(7);
    final now = DateTime(2026);

    try {
      var shown = 0;
      while (result == null) {
        expect(shown, lessThan(500000), reason: 'transfer never completed');
        for (final packet in await encoder.nextPackets(32)) {
          shown++;
          if (random.nextDouble() >= catchRate) continue;
          final bytes = Uint8List.fromList([...header, ...packet]);
          final (:action, :frame) = tracker.handle(bytes, now);
          expect(action, isIn([ScanAction.start, ScanAction.decode]));
          firstFrame ??= frame;
          await decoder.decodeChunk(frame!);
          if (result != null) break;
        }
      }
    } finally {
      encoder.dispose();
      decoder.dispose();
    }

    var data = result!;
    var wrongAttempts = 0;
    if (firstFrame!.isEncrypted) {
      Uint8List? plain;
      for (final attempt in receiverPasswords ?? [password!]) {
        try {
          plain = await TransferCrypto.decrypt(data, attempt);
          break;
        } on TransferCryptoError catch (error) {
          expect(error, TransferCryptoError.wrongPassword);
          wrongAttempts++;
        }
      }
      if (plain == null) throw TransferCryptoError.wrongPassword;
      data = plain;
    }

    final files = await saveReceivedFiles(
      data: data,
      gzipped: firstFrame.isCompressedData,
      directory: docs,
      tempDirectory: temp,
    );
    return (
      file: files.first,
      files: files,
      gzipped: transfer.gzipped,
      wrongAttempts: wrongAttempts,
    );
  }

  String nameOf(File file) => file.path.split(Platform.pathSeparator).last;

  test('compressible file arrives intact and gzipped', () async {
    final content = utf8.encode('All work and no play. ' * 20000);
    final (:file, :gzipped, wrongAttempts: _, files: _) = await send(
      'notes.txt',
      content,
    );

    expect(gzipped, isTrue);
    expect(nameOf(file), 'notes.txt');
    expect(file.readAsBytesSync(), content);
  }, skip: _skip);

  test('incompressible file arrives intact without gzip', () async {
    final content = _random(300000);
    final (:file, :gzipped, wrongAttempts: _, files: _) = await send(
      'photo.jpg',
      content,
    );

    expect(gzipped, isFalse);
    expect(nameOf(file), 'photo.jpg');
    expect(file.readAsBytesSync(), content);
  }, skip: _skip);

  test('audio/video path (gzip not tried) arrives intact', () async {
    final content = _random(100000, seed: 2);
    final (:file, :gzipped, wrongAttempts: _, files: _) = await send(
      'clip.mp4',
      content,
      tryGzip: false,
    );

    expect(gzipped, isFalse);
    expect(nameOf(file), 'clip.mp4');
    expect(file.readAsBytesSync(), content);
  }, skip: _skip);

  test('empty file arrives as an empty file', () async {
    final (:file, gzipped: _, wrongAttempts: _, files: _) = await send(
      'empty.txt',
      Uint8List(0),
    );

    expect(nameOf(file), 'empty.txt');
    expect(file.readAsBytesSync(), isEmpty);
  }, skip: _skip);

  test('heavy frame loss still delivers the exact file', () async {
    final content = _random(500000, seed: 3);
    final (:file, gzipped: _, wrongAttempts: _, files: _) = await send(
      'big.bin',
      content,
      catchRate: 0.3,
    );
    expect(file.readAsBytesSync(), content);
  }, skip: _skip);

  test(
    'large file split into several RaptorQ blocks',
    () async {
      // 96-byte symbols: ~6.5 MB spans 2 blocks.
      final content = _random(6500000, seed: 4);
      final (:file, gzipped: _, wrongAttempts: _, files: _) = await send(
        'archive.zip',
        content,
        mtu: 100,
        catchRate: 0.8,
      );
      expect(file.readAsBytesSync(), content);
    },
    skip: _skip,
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test('a sender-chosen path cannot escape the folder', () async {
    final (:file, gzipped: _, wrongAttempts: _, files: _) = await send(
      '../../escape.txt',
      utf8.encode('hi'),
    );
    expect(file.parent.path, docs.path);
    expect(nameOf(file), 'escape.txt');
  }, skip: _skip);

  test('receiving the same name twice keeps both files', () async {
    final first = await send('same.txt', utf8.encode('one'));
    final second = await send('same.txt', utf8.encode('two'));

    expect(nameOf(first.file), 'same.txt');
    expect(nameOf(second.file), 'same(1).txt');
    expect(first.file.readAsStringSync(), 'one');
    expect(second.file.readAsStringSync(), 'two');
  }, skip: _skip);

  group('encrypted', () {
    test('compressible file arrives intact, gzipped then encrypted', () async {
      final content = utf8.encode('Secret plans. ' * 20000);
      final (:file, :gzipped, :wrongAttempts, files: _) = await send(
        'plans.txt',
        content,
        password: 'K7M2-QX9P-4RTA',
      );

      expect(gzipped, isTrue);
      expect(wrongAttempts, 0);
      expect(nameOf(file), 'plans.txt');
      expect(file.readAsBytesSync(), content);
    }, skip: _skip);

    test('incompressible file arrives intact', () async {
      final content = _random(200000, seed: 5);
      final (:file, :gzipped, wrongAttempts: _, files: _) = await send(
        'photo.jpg',
        content,
        password: 'correct horse battery staple',
      );

      expect(gzipped, isFalse);
      expect(file.readAsBytesSync(), content);
    }, skip: _skip);

    test('a generated code can be typed loosely', () async {
      final content = utf8.encode('hello');
      final (:file, gzipped: _, :wrongAttempts, files: _) = await send(
        'hi.txt',
        content,
        password: 'K7M2-QX9P-4RTA',
        receiverPasswords: ['k7m2 qx9p 4rta'],
      );
      expect(wrongAttempts, 0);
      expect(file.readAsBytesSync(), content);
    }, skip: _skip);

    test('wrong passwords can be retried on the same received data', () async {
      final content = _random(50000, seed: 6);
      final (:file, gzipped: _, :wrongAttempts, files: _) = await send(
        'retry.bin',
        content,
        password: 'right password',
        receiverPasswords: ['wrong', 'Right password', 'right password'],
      );
      expect(wrongAttempts, 2);
      expect(file.readAsBytesSync(), content);
    }, skip: _skip);

    test('heavy frame loss still delivers the exact file', () async {
      final content = _random(300000, seed: 7);
      final (:file, gzipped: _, wrongAttempts: _, files: _) = await send(
        'lossy.bin',
        content,
        catchRate: 0.3,
        password: 'K7M2-QX9P-4RTA',
      );
      expect(file.readAsBytesSync(), content);
    }, skip: _skip);

    test('encryption adds a fixed overhead to the transfer', () async {
      final plain = await buildTransferObject(
        fileName: 'a.bin',
        content: _random(1000),
        tryGzip: false,
      );
      final encrypted = await buildTransferObject(
        fileName: 'a.bin',
        content: _random(1000),
        tryGzip: false,
        password: 'pw',
      );
      expect(encrypted.bytes.length, plain.bytes.length + envelopeOverhead());
      expect(envelopeOverhead(), 52);
    }, skip: _skip);
  });

  group('bundle', () {
    Future<Uint8List> zip(Map<String, String> files) async {
      final path = '${docs.parent.path}/bundle.zip';
      await writeBundle([
        for (final MapEntry(:key, :value) in files.entries)
          (name: key, path: null, bytes: utf8.encode(value)),
      ], path);
      return File(path).readAsBytesSync();
    }

    test('several files arrive as separate files', () async {
      final content = await zip({
        'notes.txt': 'All work and no play. ' * 2000,
        'list.csv': 'a,b,c\n' * 500,
        'notes(1).txt': 'second',
      });
      final (:files, :gzipped, file: _, wrongAttempts: _) = await send(
        'blastqr-bundle.zip',
        content,
        isBundle: true,
      );

      expect(gzipped, isTrue);
      expect(files.map(nameOf), ['notes.txt', 'list.csv', 'notes(1).txt']);
      expect(files[2].readAsStringSync(), 'second');
      expect(temp.listSync(), isEmpty);
    }, skip: _skip);

    test('an encrypted bundle arrives as separate files', () async {
      final content = await zip({'a.txt': 'secret a', 'b.txt': 'secret b'});
      final (:files, file: _, gzipped: _, wrongAttempts: _) = await send(
        'blastqr-bundle.zip',
        content,
        isBundle: true,
        password: 'K7M2-QX9P-4RTA',
      );

      expect(files.map(nameOf), ['a.txt', 'b.txt']);
      expect(files[1].readAsStringSync(), 'secret b');
    }, skip: _skip);

    test('a bundle that is not a zip is kept as one file', () async {
      final content = Uint8List.fromList(utf8.encode('not a zip'));
      final (:files, file: _, gzipped: _, wrongAttempts: _) = await send(
        'broken.zip',
        content,
        isBundle: true,
      );

      expect(files.map(nameOf), ['broken.zip']);
      expect(files.single.readAsBytesSync(), content);
      expect(temp.listSync(), isEmpty);
    }, skip: _skip);

    test('a zip sent without the bundle tag is kept as one file', () async {
      final content = await zip({'a.txt': 'a', 'b.txt': 'b'});
      final (:files, file: _, gzipped: _, wrongAttempts: _) = await send(
        'archive.zip',
        content,
      );

      expect(files.map(nameOf), ['archive.zip']);
    }, skip: _skip);
  });
}
