// Needs the host library: cd rust && cargo build --release
import 'dart:io';
import 'dart:typed_data';

import 'package:blastqr_crypto/blastqr_crypto.dart';
import 'package:flutter_test/flutter_test.dart';

final _libraryPath =
    'rust/target/release/librust_lib_blastqr_crypto.'
    '${Platform.isMacOS ? 'dylib' : Platform.isWindows ? 'dll' : 'so'}';

void main() {
  setUpAll(() async {
    await BlastqrCrypto.init(externalLibrary: ExternalLibrary.open(_libraryPath));
  });

  test('round trip', () async {
    final plain = Uint8List.fromList(List.generate(1000, (i) => i % 256));
    final envelope = await encryptTransfer(plain: plain, password: 'pw');
    expect(envelope.length, plain.length + envelopeOverhead());
    expect(await decryptTransfer(envelope: envelope, password: 'pw'), plain);
  });

  test('wrong password throws TransferCryptoError.wrongPassword', () async {
    final envelope = await encryptTransfer(plain: [1, 2, 3], password: 'pw');
    expect(
      () => decryptTransfer(envelope: envelope, password: 'nope'),
      throwsA(TransferCryptoError.wrongPassword),
    );
  });

  test('garbage throws TransferCryptoError.malformed', () async {
    expect(
      () => decryptTransfer(envelope: [1, 2, 3], password: 'pw'),
      throwsA(TransferCryptoError.malformed),
    );
  });
}
