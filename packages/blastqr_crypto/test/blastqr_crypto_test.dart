// Needs the host library: cd rust && cargo build --release
import 'dart:io';
import 'dart:typed_data';

import 'package:blastqr_crypto/blastqr_crypto.dart';
import 'package:flutter_test/flutter_test.dart';

final _libraryPath =
    'rust/target/release/librust_lib_blastqr_crypto.'
    '${Platform.isMacOS ? 'dylib' : Platform.isWindows ? 'dll' : 'so'}';

void main() {
  late Directory temp;

  setUpAll(() async {
    await BlastqrCrypto.init(externalLibrary: ExternalLibrary.open(_libraryPath));
  });

  setUp(() => temp = Directory.systemTemp.createTempSync('blastqr_crypto_'));

  tearDown(() => temp.deleteSync(recursive: true));

  Future<Uint8List> encrypt(List<int> plain, String password) async {
    final input = File('${temp.path}/plain.bin')..writeAsBytesSync(plain);
    final output = File('${temp.path}/sealed.bin');
    await encryptTransferFile(
      inputPath: input.path,
      outputPath: output.path,
      password: password,
    );
    return output.readAsBytesSync();
  }

  test('round trip', () async {
    final plain = Uint8List.fromList(List.generate(1000, (i) => i % 256));
    final envelope = await encrypt(plain, 'pw');
    expect(envelope.length, plain.length + envelopeOverhead());
    expect(await decryptTransfer(envelope: envelope, password: 'pw'), plain);
  });

  test('wrong password throws TransferCryptoError.wrongPassword', () async {
    final envelope = await encrypt([1, 2, 3], 'pw');
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
