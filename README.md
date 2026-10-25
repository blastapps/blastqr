# blastQR

Send files between devices with an animated sequence of QR codes. No internet,
Wi-Fi, Bluetooth or cable needed: one screen shows the codes and the other
device's camera reads them.

## Features

- **Works fully offline.** The only link between devices is the screen and the
  camera.
- **Resilient to missed frames.** Files are encoded with
  [RaptorQ](https://en.wikipedia.org/wiki/Raptor_code), a fountain code, so the
  receiver can rebuild the file from any large enough set of frames, in any
  order.
- **Multiple codes on screen.** Shows up to 6 QR codes at once for higher
  speed. Transfers peak at around 110 kB/s, so it suits small files best.
- **Completion signal by sound.** When the receiver has the whole file it plays
  a short tone, and the sender's microphone picks it up to stop the transfer.
- **Several files at once.** They're zipped into one transfer and unpacked
  into separate files on the receiver.
- **Optional password encryption.** The sender gets a generated password to
  share with the receiver, who types it in once the file has arrived.
- **Optional image compression and gzip** to shrink files before sending.
- **Regular QR scanner.** Normal QR codes are shown as text.
- Available in English, Spanish, Catalan and Korean.

## Platforms

| Platform | Send | Receive |
|---|:-:|:-:|
| Android | ✓ | ✓ |
| iOS | ✓ | ✓ |
| macOS | ✓ | ✓ |
| Windows | ✓ | |
| Linux | ✓ | ✓ |

## Security note

Without encryption, anyone who can see or record the QR codes can read the
file.

With "Send password-encrypted", the file and its name are encrypted
(Argon2id and ChaCha20-Poly1305), and a recording of the codes is useless
without the password. Share the password by saying it or showing it, not where
a camera can see it. The size of the file can still be seen, and a weak custom
password can be guessed from a recording.

Received files are saved unencrypted on the receiving device.

## How it works

The sender splits the file into packets with RaptorQ, adds extra repair
packets, puts a small header on each one and loops them as QR codes. The
receiver scans until it has enough packets, rebuilds the file and saves it.

See [docs/protocol.md](docs/protocol.md) for the full format and design notes.

## Building from source

You need:

- [Flutter](https://docs.flutter.dev/get-started/install) (stable channel,
  Flutter 3.41 / Dart 3.11 or newer)
- [Rust](https://www.rust-lang.org/tools/install) installed with rustup,
  which builds the RaptorQ and encryption libraries. The targets for your
  platform are installed automatically from `rust-toolchain.toml`.
- The usual platform tools: Xcode for iOS/macOS, Android Studio or the Android
  SDK for Android. Android also needs NDK 27 or newer.
- On Linux, the GStreamer development packages for the camera
  (`libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
  gstreamer1.0-plugins-good` on Ubuntu/Debian).

Two native packages live in separate repos and must be checked out next to
this one: `raptorq_flutter` (RaptorQ) and `blastqr_crypto` (encryption).

```sh
git clone https://codeberg.org/cukha/raptorq_flutter.git
git clone https://codeberg.org/cukha/blastqr_crypto.git
git clone https://codeberg.org/cukha/blastqr.git
cd blastqr
flutter pub get
flutter run
```

<!-- TODO: publish raptorq_flutter and blastqr_crypto and confirm the URLs above. -->

### Running the tests

`flutter test` runs everything. The round-trip tests load both native
libraries built for your computer, and are skipped until they're built:

```sh
(cd ../raptorq_flutter/rust && cargo build --release)
(cd ../blastqr_crypto/rust && cargo build --release)
```

### Release signing (Android)

Release builds read signing settings from `android/key.properties`, which is
not in the repo. Without it, use `flutter run` or a debug build.

## Project layout

| Path | Contents |
|---|---|
| `lib/features/send/` | Picking files, encoding and showing QR codes |
| `lib/features/scan/` | Camera scanning and decoding |
| `lib/features/files_received/` | Received files list |
| `lib/features/settings/` | Settings screens |
| `lib/raptorq/` | Wrappers around the RaptorQ encoder and decoder |
| `lib/crypto/` | Passwords and the wrapper around `blastqr_crypto` |
| `lib/l10n/` | Translations (`.arb` files) |
| `docs/` | Protocol documentation |

## Translations

Strings live in `lib/l10n/app_<language>.arb`. To add a language, copy
`app_en.arb`, translate the values and run `flutter gen-l10n` (or just
`flutter run`).

## License

blastQR is licensed under the [GNU Affero General Public License v3.0](LICENSE).

Bundled third-party components keep their own licenses:

- [Jersey 25](https://github.com/scfried/soft-type-jersey) font, SIL Open Font
  License 1.1 ([fonts/Jersey25/OFL.txt](fonts/Jersey25/OFL.txt))
- [raptorq](https://github.com/cberner/raptorq) crate, Apache License 2.0
  ([assets/licenses/raptorq.txt](assets/licenses/raptorq.txt))
- [argon2](https://github.com/RustCrypto/password-hashes) and
  [chacha20poly1305](https://github.com/RustCrypto/AEADs) crates, MIT or
  Apache License 2.0
