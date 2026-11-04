/// Password-based encryption of BlastQR transfer objects.
///
/// ```dart
/// await BlastqrCrypto.init();
/// final envelope = await encryptTransfer(plain: bytes, password: pw);
/// final plain = await decryptTransfer(envelope: envelope, password: pw);
/// ```
library;

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show ExternalLibrary;

import 'src/rust/frb_generated.dart';

export 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show ExternalLibrary;
export 'src/rust/api/crypto.dart'
    show
        TransferCryptoError,
        decryptTransfer,
        encryptTransfer,
        envelopeOverhead;

abstract final class BlastqrCrypto {
  /// Loads the native library. Call once before anything else.
  ///
  /// In an app, the build hook bundles the library where the default loader
  /// finds it. Tests pass [externalLibrary] to load a host build, e.g.
  /// `ExternalLibrary.open('rust/target/release/librust_lib_blastqr_crypto.dylib')`.
  static Future<void> init({ExternalLibrary? externalLibrary}) {
    return RustLib.init(externalLibrary: externalLibrary);
  }
}
