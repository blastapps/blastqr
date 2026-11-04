//! Password-based encryption of a BlastQR transfer object.
//! The envelope format is described in the `blastqr_envelope` crate.

use blastqr_envelope::{self as envelope, EnvelopeError};

/// Why a transfer couldn't be decrypted.
pub enum TransferCryptoError {
    /// Wrong password, or the data was changed.
    WrongPassword,
    /// Not an envelope this version understands, or too short.
    Malformed,
    /// Key derivation settings outside the accepted range.
    UnsupportedParams,
}

impl From<EnvelopeError> for TransferCryptoError {
    fn from(e: EnvelopeError) -> Self {
        match e {
            EnvelopeError::WrongPassword => TransferCryptoError::WrongPassword,
            EnvelopeError::Malformed => TransferCryptoError::Malformed,
            EnvelopeError::UnsupportedParams => TransferCryptoError::UnsupportedParams,
        }
    }
}

/// Bytes the envelope adds to the plaintext.
#[flutter_rust_bridge::frb(sync)]
pub fn envelope_overhead() -> u32 {
    envelope::ENVELOPE_OVERHEAD as u32
}

/// Encrypts `plain` with a key derived from `password` (Argon2id,
/// 64 MiB, 3 iterations), using ChaCha20-Poly1305.
pub fn encrypt_transfer(plain: Vec<u8>, password: String) -> Vec<u8> {
    envelope::encrypt(&plain, &password)
}

/// Decrypts an envelope made by [encrypt_transfer].
pub fn decrypt_transfer(
    envelope: Vec<u8>,
    password: String,
) -> Result<Vec<u8>, TransferCryptoError> {
    Ok(envelope::decrypt(&envelope, &password)?)
}
