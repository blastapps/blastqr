//! Password-based encryption of a BlastQR transfer object.
//! The envelope format is described in the `blastqr_envelope` crate.

use std::fs::{File, OpenOptions};
use std::io::Read;

use blastqr_envelope::{self as envelope, EnvelopeError};
use memmap2::MmapMut;

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

/// Encrypts the file at `input_path` into a new file at `output_path`, with
/// a key derived from `password` (Argon2id, 64 MiB, 3 iterations), using
/// ChaCha20-Poly1305. Neither is held in memory: the output is
/// memory-mapped and encrypted in place.
pub fn encrypt_transfer_file(
    input_path: String,
    output_path: String,
    password: String,
) -> anyhow::Result<()> {
    let mut input = File::open(&input_path)?;
    let len = input.metadata()?.len() as usize;
    let output = OpenOptions::new()
        .read(true)
        .write(true)
        .create_new(true)
        .open(&output_path)?;
    output.set_len((envelope::ENVELOPE_OVERHEAD + len) as u64)?;
    // Safety: the file was just created, so nothing else changes it.
    let mut map = unsafe { MmapMut::map_mut(&output)? };
    input.read_exact(&mut map[envelope::HEADER_LEN..envelope::HEADER_LEN + len])?;
    envelope::seal_in_place(&mut map, &password);
    map.flush()?;
    Ok(())
}

/// Decrypts an envelope made by [encrypt_transfer_file].
pub fn decrypt_transfer(
    envelope: Vec<u8>,
    password: String,
) -> Result<Vec<u8>, TransferCryptoError> {
    Ok(envelope::decrypt(&envelope, &password)?)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn file_encryption_decrypts() {
        let dir = std::env::temp_dir();
        let input = dir.join("blastqr_crypto_plain.bin");
        let output = dir.join("blastqr_crypto_sealed.bin");
        let _ = std::fs::remove_file(&output);
        let plain: Vec<u8> = (0..100_003).map(|i| (i * 7 % 256) as u8).collect();
        std::fs::write(&input, &plain).unwrap();

        encrypt_transfer_file(
            input.to_str().unwrap().into(),
            output.to_str().unwrap().into(),
            "pw".into(),
        )
        .unwrap();

        let sealed = std::fs::read(&output).unwrap();
        assert_eq!(sealed.len(), plain.len() + envelope::ENVELOPE_OVERHEAD);
        assert!(decrypt_transfer(sealed, "pw".into()).ok() == Some(plain));
        std::fs::remove_file(&input).unwrap();
        std::fs::remove_file(&output).unwrap();
    }
}
