//! QR code generation for frames: byte mode, error correction level L.

use fast_qr::{ECL, Mode, QRBuilder, Version};

/// Byte capacity of each QR version (index 0 = version 1) at level L.
const CAPACITY_L: [usize; 40] = [
    17, 32, 53, 78, 106, 134, 154, 192, 230, 271, 321, 367, 425, 458, 520, 586, 644, 718, 792, 858,
    929, 1003, 1091, 1171, 1273, 1367, 1465, 1528, 1628, 1732, 1840, 1952, 2068, 2188, 2303, 2431,
    2563, 2699, 2809, 2953,
];

pub const MAX_VERSION: u8 = 40;

pub fn capacity(version: u8) -> usize {
    CAPACITY_L[version as usize - 1]
}

/// Modules per side, without quiet zone.
pub fn modules(version: u8) -> usize {
    17 + 4 * version as usize
}

/// Smallest version that holds `len` bytes.
pub fn version_for(len: usize) -> Option<u8> {
    (1..=MAX_VERSION).find(|&v| capacity(v) >= len)
}

/// A square grid of modules, row-major, `true` = dark.
pub struct Matrix {
    pub size: usize,
    pub dark: Vec<bool>,
}

impl Matrix {
    pub fn is_dark(&self, row: usize, col: usize) -> bool {
        self.dark[row * self.size + col]
    }
}

pub fn encode(bytes: &[u8], version: u8) -> Matrix {
    let qr = QRBuilder::new(bytes.to_vec())
        .ecl(ECL::L)
        .mode(Mode::Byte)
        .version(VERSIONS[version as usize - 1])
        .build()
        .expect("frame fits the chosen QR version");
    let size = qr.size;
    Matrix {
        size,
        dark: qr.data[..size * size].iter().map(|m| m.value()).collect(),
    }
}

const VERSIONS: [Version; 40] = {
    use Version::*;
    [
        V01, V02, V03, V04, V05, V06, V07, V08, V09, V10, V11, V12, V13, V14, V15, V16, V17, V18,
        V19, V20, V21, V22, V23, V24, V25, V26, V27, V28, V29, V30, V31, V32, V33, V34, V35, V36,
        V37, V38, V39, V40,
    ]
};
