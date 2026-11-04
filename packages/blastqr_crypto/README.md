# blastqr_crypto

Password-based encryption for BlastQR transfer objects, in Rust via
flutter_rust_bridge. Argon2id derives the key, ChaCha20-Poly1305 encrypts.
The encryption itself is in the `blastqr_envelope` crate next to this
package, which the CLI uses too. The envelope format is documented there and
in BlastQR's `docs/protocol.md`.

Build/test the Rust side: `cd rust && cargo test && cargo build --release`,
After changing `rust/src/api/`, regenerate bindings with
`flutter_rust_bridge_codegen generate`.

Apps get the native library from the build hook (`hook/build.dart`, via
`native_toolchain_rust`), which compiles the crate for the target and has
Flutter bundle it as a dynamic library. Building for iOS/Android needs rustup
with the targets listed in `rust/rust-toolchain.toml`, and the Android NDK 27+.
