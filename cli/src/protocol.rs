//! BlastQR protocol version 3, sender side. See `blastqr/docs/protocol.md`.

use std::io::Write;

use flate2::Compression;
use flate2::write::GzEncoder;

use crate::{envelope, password};

pub const SIGNATURE: &[u8; 3] = b"bQR";
pub const PROTOCOL_VERSION: u8 = 3;
pub const HEADER_LEN: usize = 14;
pub const PACKET_ID_LEN: usize = 4;

pub const FLAG_GZIP: u8 = 0x01;
pub const FLAG_ENCRYPTED: u8 = 0x02;
pub const KIND_FILE: u8 = 0;

pub const TAG_FILE_NAME: u8 = 1;
/// Empty; the content is a zip of several files.
pub const TAG_BUNDLE: u8 = 2;
pub const MAX_FILE_NAME_BYTES: usize = 255;

/// Symbol size range the reference sender uses.
pub const MIN_SYMBOL_SIZE: usize = 96;
pub const MAX_SYMBOL_SIZE: usize = 2928;

/// Most file content a transfer can hold: the 4 GB length field, minus room
/// for metadata (as in the app).
pub const MAX_CONTENT_BYTES: u64 = 0xFFFF_FFFF - 1024;

/// Receivers refuse transfers with more symbols than this.
pub const MAX_SYMBOL_COUNT: usize = 1_500_000;

/// Bytes per frame besides the symbol itself.
pub const FRAME_OVERHEAD: usize = HEADER_LEN + PACKET_ID_LEN;

/// File types that are already compressed, so gzip would only cost time.
const PRECOMPRESSED: &[&str] = &[
    "mp4", "mov", "m4v", "mkv", "webm", "avi", "mp3", "m4a", "aac", "ogg", "opus", "flac", "zip",
    "gz", "tgz", "bz2", "xz", "zst", "7z", "rar", "jpg", "jpeg", "png", "gif", "webp", "heic",
    "avif",
];

pub fn is_precompressed(file_name: &str) -> bool {
    match file_name.rsplit_once('.') {
        Some((_, ext)) => PRECOMPRESSED.contains(&ext.to_ascii_lowercase().as_str()),
        None => false,
    }
}

pub struct TransferObject {
    pub bytes: Vec<u8>,
    pub gzipped: bool,
    pub encrypted: bool,
}

impl TransferObject {
    /// Metadata + content, gzipped if `try_gzip` and smaller, then encrypted
    /// if a password is given. `is_bundle` marks the content as a zip of
    /// several files.
    pub fn build(
        file_name: &str,
        is_bundle: bool,
        content: &[u8],
        try_gzip: bool,
        password: Option<&str>,
    ) -> TransferObject {
        let mut bytes = encode_metadata(file_name, is_bundle);
        bytes.extend_from_slice(content);

        let mut gzipped = false;
        if try_gzip {
            let mut gz = GzEncoder::new(Vec::new(), Compression::default());
            gz.write_all(&bytes).expect("writing to a Vec can't fail");
            let compressed = gz.finish().expect("writing to a Vec can't fail");
            if compressed.len() < bytes.len() {
                bytes = compressed;
                gzipped = true;
            }
        }
        if let Some(password) = password {
            bytes = envelope::encrypt(&bytes, &password::normalize(password));
        }
        TransferObject {
            bytes,
            gzipped,
            encrypted: password.is_some(),
        }
    }

    pub fn flags(&self) -> u8 {
        (if self.gzipped { FLAG_GZIP } else { 0 })
            | (if self.encrypted { FLAG_ENCRYPTED } else { 0 })
    }
}

/// The metadata block with its 2-byte length prefix.
pub fn encode_metadata(file_name: &str, is_bundle: bool) -> Vec<u8> {
    let name = truncate_utf8(file_name, MAX_FILE_NAME_BYTES).as_bytes();
    let mut body = vec![TAG_FILE_NAME];
    body.extend_from_slice(&(name.len() as u16).to_be_bytes());
    body.extend_from_slice(name);
    if is_bundle {
        body.extend_from_slice(&[TAG_BUNDLE, 0, 0]);
    }
    let mut out = (body.len() as u16).to_be_bytes().to_vec();
    out.extend_from_slice(&body);
    out
}

fn truncate_utf8(s: &str, max: usize) -> &str {
    if s.len() <= max {
        return s;
    }
    let mut cut = max;
    while !s.is_char_boundary(cut) {
        cut -= 1;
    }
    &s[..cut]
}

/// The 14-byte header every frame of a transfer shares.
pub fn frame_header(
    flags: u8,
    session_id: u16,
    transfer_length: u32,
    symbol_size: u16,
) -> [u8; HEADER_LEN] {
    let mut h = [0u8; HEADER_LEN];
    h[0..3].copy_from_slice(SIGNATURE);
    h[3] = PROTOCOL_VERSION;
    h[4] = flags;
    h[5] = KIND_FILE;
    h[6..8].copy_from_slice(&session_id.to_be_bytes());
    h[8..12].copy_from_slice(&transfer_length.to_be_bytes());
    h[12..14].copy_from_slice(&symbol_size.to_be_bytes());
    h
}

pub fn random_session_id() -> u16 {
    use rand_core::{OsRng, RngCore};
    (OsRng.next_u32() % 0xFFFF) as u16 + 1
}

pub fn fits_symbol_limit(transfer_length: usize, symbol_size: usize) -> bool {
    transfer_length.div_ceil(symbol_size) <= MAX_SYMBOL_COUNT
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn metadata_layout() {
        assert_eq!(
            encode_metadata("a.txt", false),
            [0, 8, 1, 0, 5, b'a', b'.', b't', b'x', b't']
        );
        assert_eq!(
            encode_metadata("a.zip", true),
            [0, 11, 1, 0, 5, b'a', b'.', b'z', b'i', b'p', 2, 0, 0]
        );
    }

    #[test]
    fn long_names_are_cut_on_a_char_boundary() {
        let name = "é".repeat(200);
        let meta = encode_metadata(&name, false);
        assert_eq!(u16::from_be_bytes([meta[3], meta[4]]), 254);
    }

    #[test]
    fn gzip_only_when_smaller() {
        assert!(TransferObject::build("a.txt", false, &[b'a'; 10_000], true, None).gzipped);
        assert!(!TransferObject::build("a.txt", false, b"x", true, None).gzipped);
    }
}
