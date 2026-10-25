// Sends files through the real sender and receiver code, minus the camera:
// sender payload + header → RaptorQ stream → frame bytes → receiver's
// tracker, decoder, decryption and file saving. Uses the RaptorQ and crypto
// libraries built for this machine; build them first:
//   (cd ../raptorq_flutter/rust && cargo build --release)
//   (cd ../blastqr_crypto/rust && cargo build --release)
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:blast_qr/crypto/transfer_crypto.dart';
import 'package:blast_qr/features/scan/received_file_writer.dart';
import 'package:blast_qr/features/scan/transfer_tracker.dart';
import 'package:blast_qr/features/send/helpers/file_qr_encoder.dart';
import 'package:blast_qr/model/blast_qrcode_data.dart';
import 'package:blast_qr/raptorq/raptorq_decoder.dart';
import 'package:blast_qr/raptorq/raptorq_streaming_encoder.dart';
import 'package:blastqr_crypto/blastqr_crypto.dart'
    show BlastqrCrypto, envelopeOverhead;
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raptorq_flutter/src/rust/frb_generated.dart';

const _libraryPath =
    '../raptorq_flutter/rust/target/release/librust_lib_raptorq_dart.dylib';

const _cryptoLibraryPath =
    '../blastqr_crypto/rust/target/release/librust_lib_blastqr_crypto.dylib';

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
  /// app does), counting wrong ones in `wrongAttempts`.
  Future<({File file, bool gzipped, int wrongAttempts})> send(
    String fileName,
    Uint8List content, {
    bool tryGzip = true,
    int mtu = 2935,
    double catchRate = 1,
    String? password,
    List<String>? receiverPasswords,
  }) async {
    // Sender.
    final transfer = await buildTransferObject(
      fileName: fileName,
      content: content,
      tryGzip: tryGzip,
      password: password,
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

    final file = await saveReceivedFile(
      data: data,
      gzipped: firstFrame.isCompressedData,
      directory: docs,
      tempDirectory: temp,
    );
    return (file: file, gzipped: transfer.gzipped, wrongAttempts: wrongAttempts);
  }

  String nameOf(File file) => file.path.split(Platform.pathSeparator).last;

  test('compressible file arrives intact and gzipped', () async {
    final content = utf8.encode('All work and no play. ' * 20000);
    final (:file, :gzipped, wrongAttempts: _) = await send('notes.txt', content);

    expect(gzipped, isTrue);
    expect(nameOf(file), 'notes.txt');
    expect(file.readAsBytesSync(), content);
  }, skip: _skip);

  test('incompressible file arrives intact without gzip', () async {
    final content = _random(300000);
    final (:file, :gzipped, wrongAttempts: _) = await send('photo.jpg', content);

    expect(gzipped, isFalse);
    expect(nameOf(file), 'photo.jpg');
    expect(file.readAsBytesSync(), content);
  }, skip: _skip);

  test('audio/video path (gzip not tried) arrives intact', () async {
    final content = _random(100000, seed: 2);
    final (:file, :gzipped, wrongAttempts: _) = await send(
      'clip.mp4',
      content,
      tryGzip: false,
    );

    expect(gzipped, isFalse);
    expect(nameOf(file), 'clip.mp4');
    expect(file.readAsBytesSync(), content);
  }, skip: _skip);

  test('empty file arrives as an empty file', () async {
    final (:file, gzipped: _, wrongAttempts: _) = await send('empty.txt', Uint8List(0));

    expect(nameOf(file), 'empty.txt');
    expect(file.readAsBytesSync(), isEmpty);
  }, skip: _skip);

  test('heavy frame loss still delivers the exact file', () async {
    final content = _random(500000, seed: 3);
    final (:file, gzipped: _, wrongAttempts: _) = await send(
      'big.bin',
      content,
      catchRate: 0.3,
    );
    expect(file.readAsBytesSync(), content);
  }, skip: _skip);

  test('large file split into several RaptorQ blocks', () async {
    // 96-byte symbols: ~6.5 MB spans 2 blocks.
    final content = _random(6500000, seed: 4);
    final (:file, gzipped: _, wrongAttempts: _) = await send(
      'archive.zip',
      content,
      mtu: 100,
      catchRate: 0.8,
    );
    expect(file.readAsBytesSync(), content);
  }, skip: _skip, timeout: const Timeout(Duration(minutes: 5)));

  test('a sender-chosen path cannot escape the folder', () async {
    final (:file, gzipped: _, wrongAttempts: _) = await send(
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
      final (:file, :gzipped, :wrongAttempts) = await send(
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
      final (:file, :gzipped, wrongAttempts: _) = await send(
        'photo.jpg',
        content,
        password: 'correct horse battery staple',
      );

      expect(gzipped, isFalse);
      expect(file.readAsBytesSync(), content);
    }, skip: _skip);

    test('a generated code can be typed loosely', () async {
      final content = utf8.encode('hello');
      final (:file, gzipped: _, :wrongAttempts) = await send(
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
      final (:file, gzipped: _, :wrongAttempts) = await send(
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
      final (:file, gzipped: _, wrongAttempts: _) = await send(
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
      expect(
        encrypted.bytes.length,
        plain.bytes.length + envelopeOverhead(),
      );
      expect(envelopeOverhead(), 52);
    }, skip: _skip);
  });
}
