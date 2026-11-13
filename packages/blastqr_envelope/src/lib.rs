//! Password-based encryption of a whole transfer object.
//!
//! Envelope layout (all integers big-endian):
//!
//! ```text
//! offset size  field
//! 0      1     envelope version = 1
//! 1      1     kdf = 1 (Argon2id)
//! 2      4     memory in KiB, u32
//! 6      1     iterations
//! 7      1     parallelism
//! 8      16    salt
//! 24     12    nonce
//! 36     n+16  ChaCha20-Poly1305 ciphertext + tag, AAD = bytes 0..36
//! ```

use argon2::{Algorithm, Argon2, Params, Version};
use chacha20poly1305::aead::{Aead, AeadInPlace, KeyInit, Payload};
use chacha20poly1305::{ChaCha20Poly1305, Key, Nonce};
use rand_core::{OsRng, RngCore};
use zeroize::Zeroizing;

const ENVELOPE_VERSION: u8 = 1;
const KDF_ARGON2ID: u8 = 1;
const SALT_LEN: usize = 16;
const NONCE_LEN: usize = 12;
const TAG_LEN: usize = 16;
/// Where the ciphertext starts, after the header.
pub const HEADER_LEN: usize = 8 + SALT_LEN + NONCE_LEN;

/// Bytes the envelope adds to the plaintext.
pub const ENVELOPE_OVERHEAD: usize = HEADER_LEN + TAG_LEN;

/// Default key derivation settings for new transfers.
const DEFAULT_MEMORY_KIB: u32 = 64 * 1024;
const DEFAULT_ITERATIONS: u8 = 3;
const DEFAULT_PARALLELISM: u8 = 1;

/// Highest settings a receiver accepts. A crafted stream could otherwise ask
/// for gigabytes of memory or minutes of work.
const MAX_MEMORY_KIB: u32 = 256 * 1024;
const MAX_ITERATIONS: u8 = 10;
const MAX_PARALLELISM: u8 = 4;

/// Why a transfer couldn't be decrypted.
#[derive(Debug, PartialEq, Eq)]
pub enum EnvelopeError {
    /// Wrong password, or the data was changed.
    WrongPassword,
    /// Not an envelope this version understands, or too short.
    Malformed,
    /// Key derivation settings outside the accepted range.
    UnsupportedParams,
}

/// Encrypts `plain` with a key derived from `password`.
pub fn encrypt(plain: &[u8], password: &str) -> Vec<u8> {
    let mut envelope = envelope_for(plain);
    seal_in_place(&mut envelope, password);
    envelope
}

/// Encrypts in place, for data too large to copy: `envelope` holds the
/// plaintext from [HEADER_LEN] up to its last 16 bytes, and gets the header
/// and tag written around it. The result is the same as [encrypt]'s.
///
/// Panics if `envelope` is shorter than [ENVELOPE_OVERHEAD].
pub fn seal_in_place(envelope: &mut [u8], password: &str) {
    let mut salt = [0u8; SALT_LEN];
    let mut nonce = [0u8; NONCE_LEN];
    OsRng.fill_bytes(&mut salt);
    OsRng.fill_bytes(&mut nonce);
    seal_in_place_with(
        envelope,
        password,
        DEFAULT_MEMORY_KIB,
        DEFAULT_ITERATIONS,
        DEFAULT_PARALLELISM,
        salt,
        nonce,
    );
}

/// `plain`, with room for the header and tag around it.
fn envelope_for(plain: &[u8]) -> Vec<u8> {
    let mut envelope = vec![0; ENVELOPE_OVERHEAD + plain.len()];
    envelope[HEADER_LEN..HEADER_LEN + plain.len()].copy_from_slice(plain);
    envelope
}

/// Decrypts an envelope made by [encrypt].
pub fn decrypt(envelope: &[u8], password: &str) -> Result<Vec<u8>, EnvelopeError> {
    if envelope.len() < ENVELOPE_OVERHEAD {
        return Err(EnvelopeError::Malformed);
    }
    let (header, body) = envelope.split_at(HEADER_LEN);
    if header[0] != ENVELOPE_VERSION || header[1] != KDF_ARGON2ID {
        return Err(EnvelopeError::Malformed);
    }
    let memory_kib = u32::from_be_bytes([header[2], header[3], header[4], header[5]]);
    let iterations = header[6];
    let parallelism = header[7];
    if memory_kib > MAX_MEMORY_KIB
        || iterations == 0
        || iterations > MAX_ITERATIONS
        || parallelism == 0
        || parallelism > MAX_PARALLELISM
    {
        return Err(EnvelopeError::UnsupportedParams);
    }
    let salt = &header[8..8 + SALT_LEN];
    let nonce = &header[8 + SALT_LEN..HEADER_LEN];

    let key = derive_key(password, salt, memory_kib, iterations, parallelism)
        .ok_or(EnvelopeError::UnsupportedParams)?;
    let cipher = ChaCha20Poly1305::new(Key::from_slice(key.as_slice()));
    cipher
        .decrypt(
            Nonce::from_slice(nonce),
            Payload {
                msg: body,
                aad: header,
            },
        )
        .map_err(|_| EnvelopeError::WrongPassword)
}

fn seal_in_place_with(
    envelope: &mut [u8],
    password: &str,
    memory_kib: u32,
    iterations: u8,
    parallelism: u8,
    salt: [u8; SALT_LEN],
    nonce: [u8; NONCE_LEN],
) {
    let (header, rest) = envelope.split_at_mut(HEADER_LEN);
    let (body, tag) = rest.split_at_mut(rest.len() - TAG_LEN);
    header[0] = ENVELOPE_VERSION;
    header[1] = KDF_ARGON2ID;
    header[2..6].copy_from_slice(&memory_kib.to_be_bytes());
    header[6] = iterations;
    header[7] = parallelism;
    header[8..8 + SALT_LEN].copy_from_slice(&salt);
    header[8 + SALT_LEN..].copy_from_slice(&nonce);

    let key = derive_key(password, &salt, memory_kib, iterations, parallelism)
        .expect("default key derivation settings are valid");
    let cipher = ChaCha20Poly1305::new(Key::from_slice(key.as_slice()));
    let sealed_tag = cipher
        .encrypt_in_place_detached(Nonce::from_slice(&nonce), header, body)
        .expect("ChaCha20-Poly1305 encryption can't fail for in-memory data");
    tag.copy_from_slice(&sealed_tag);
}

/// Argon2id key, wiped from memory when dropped. `None` if the settings are
/// rejected by the argon2 crate (e.g. memory too small).
fn derive_key(
    password: &str,
    salt: &[u8],
    memory_kib: u32,
    iterations: u8,
    parallelism: u8,
) -> Option<Zeroizing<[u8; 32]>> {
    let params = Params::new(memory_kib, iterations as u32, parallelism as u32, Some(32)).ok()?;
    let argon2 = Argon2::new(Algorithm::Argon2id, Version::V0x13, params);
    let mut key = Zeroizing::new([0u8; 32]);
    argon2
        .hash_password_into(password.as_bytes(), salt, key.as_mut())
        .ok()?;
    Some(key)
}

#[cfg(test)]
mod tests {
    use super::*;

    // Small settings so tests run fast.
    fn seal(plain: &[u8], password: &str) -> Vec<u8> {
        let mut envelope = envelope_for(plain);
        seal_in_place_with(
            &mut envelope,
            password,
            64,
            1,
            1,
            [7; SALT_LEN],
            [9; NONCE_LEN],
        );
        envelope
    }

    #[test]
    fn same_as_one_shot_encryption() {
        // The format before in-place sealing: header, then the AEAD output.
        let plain = b"hello world";
        let env = seal(plain, "pw");
        let header = &env[..HEADER_LEN];
        let key = derive_key("pw", &[7; SALT_LEN], 64, 1, 1).unwrap();
        let sealed = ChaCha20Poly1305::new(Key::from_slice(key.as_slice()))
            .encrypt(
                Nonce::from_slice(&[9; NONCE_LEN]),
                Payload {
                    msg: plain,
                    aad: header,
                },
            )
            .unwrap();
        assert_eq!(&env[HEADER_LEN..], &sealed[..]);
    }

    #[test]
    fn round_trip() {
        let env = seal(b"hello world", "pw");
        assert_eq!(env.len(), 11 + ENVELOPE_OVERHEAD);
        assert_eq!(decrypt(&env, "pw").unwrap(), b"hello world");
    }

    #[test]
    fn round_trip_default_settings() {
        let env = encrypt(b"data", "K7M2QX9P4RTA");
        assert_eq!(&env[2..6], &DEFAULT_MEMORY_KIB.to_be_bytes());
        assert_eq!(decrypt(&env, "K7M2QX9P4RTA").unwrap(), b"data");
    }

    #[test]
    fn empty_plaintext() {
        let env = seal(b"", "pw");
        assert_eq!(decrypt(&env, "pw").unwrap(), b"");
    }

    #[test]
    fn wrong_password() {
        let env = seal(b"secret", "pw");
        assert_eq!(decrypt(&env, "nope"), Err(EnvelopeError::WrongPassword));
    }

    #[test]
    fn flipped_byte_in_body_or_header() {
        let env = seal(b"secret", "pw");
        for i in [8, 30, HEADER_LEN, env.len() - 1] {
            let mut bad = env.clone();
            bad[i] ^= 1;
            assert_eq!(
                decrypt(&bad, "pw"),
                Err(EnvelopeError::WrongPassword),
                "byte {i}"
            );
        }
    }

    #[test]
    fn rejects_expensive_settings() {
        let env = seal(b"x", "pw");
        let mut big_memory = env.clone();
        big_memory[2..6].copy_from_slice(&(MAX_MEMORY_KIB + 1).to_be_bytes());
        let mut many_iterations = env.clone();
        many_iterations[6] = MAX_ITERATIONS + 1;
        let mut zero_iterations = env.clone();
        zero_iterations[6] = 0;
        let mut many_lanes = env.clone();
        many_lanes[7] = MAX_PARALLELISM + 1;
        for bad in [big_memory, many_iterations, zero_iterations, many_lanes] {
            assert_eq!(decrypt(&bad, "pw"), Err(EnvelopeError::UnsupportedParams));
        }
    }

    #[test]
    fn malformed() {
        let env = seal(b"x", "pw");
        assert_eq!(
            decrypt(&env[..ENVELOPE_OVERHEAD - 1], "pw"),
            Err(EnvelopeError::Malformed)
        );
        let mut wrong_version = env.clone();
        wrong_version[0] = 2;
        assert_eq!(decrypt(&wrong_version, "pw"), Err(EnvelopeError::Malformed));
        let mut wrong_kdf = env;
        wrong_kdf[1] = 2;
        assert_eq!(decrypt(&wrong_kdf, "pw"), Err(EnvelopeError::Malformed));
    }
}
