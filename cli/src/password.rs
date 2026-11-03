//! Generated transfer codes, matching the app's `lib/crypto/password.dart`.

use rand_core::{OsRng, RngCore};

/// Crockford base32: no I, L, O or U.
const ALPHABET: &[u8] = b"0123456789ABCDEFGHJKMNPQRSTVWXYZ";
const CODE_LENGTH: usize = 12;
pub const MIN_RECOMMENDED_LENGTH: usize = 8;

/// A random code like `K7M2-QX9P-4RTA`.
pub fn generate() -> String {
    let code: String = (0..CODE_LENGTH)
        .map(|_| ALPHABET[(OsRng.next_u32() % ALPHABET.len() as u32) as usize] as char)
        .collect();
    format_code(&code)
}

/// What gets fed to the key derivation. A generated code can be typed
/// loosely (any case, dashes or spaces, O/I/L for 0/1/1). Custom passwords
/// are only trimmed.
pub fn normalize(password: &str) -> String {
    as_code(password).unwrap_or_else(|| password.trim().to_string())
}

fn format_code(code: &str) -> String {
    code.as_bytes()
        .chunks(4)
        .map(|c| std::str::from_utf8(c).unwrap())
        .collect::<Vec<_>>()
        .join("-")
}

fn as_code(password: &str) -> Option<String> {
    let mut code = String::new();
    for c in password.trim().to_uppercase().chars() {
        let c = match c {
            '-' | ' ' => continue,
            'O' => '0',
            'I' | 'L' => '1',
            c => c,
        };
        if !c.is_ascii() || !ALPHABET.contains(&(c as u8)) {
            return None;
        }
        code.push(c);
    }
    (code.len() == CODE_LENGTH).then_some(code)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn generated_code_normalizes_to_itself_without_dashes() {
        let code = generate();
        assert_eq!(code.len(), 14);
        assert_eq!(normalize(&code), code.replace('-', ""));
    }

    #[test]
    fn loose_typing() {
        assert_eq!(normalize(" k7m2-qx9p-4rta "), "K7M2QX9P4RTA");
        assert_eq!(normalize("OIL2 QX9P 4RTA"), "0112QX9P4RTA");
    }

    #[test]
    fn custom_passwords_are_trimmed_only() {
        assert_eq!(normalize("  my Secret "), "my Secret");
    }
}
