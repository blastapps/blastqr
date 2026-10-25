import 'dart:typed_data';

import 'package:blast_qr/crypto/password.dart';
import 'package:blastqr_crypto/blastqr_crypto.dart';

export 'package:blastqr_crypto/blastqr_crypto.dart' show TransferCryptoError;

abstract final class TransferCrypto {
  static Future<Uint8List> encrypt(Uint8List plain, String password) =>
      encryptTransfer(plain: plain, password: normalizePassword(password));

  static Future<Uint8List> decrypt(Uint8List envelope, String password) =>
      decryptTransfer(envelope: envelope, password: normalizePassword(password));
}
