//! Several files sent as one zip, as the app does (see "Bundles" in
//! `blastqr/docs/protocol.md`): entries stored without compression, plain
//! file names made unique within the zip.

use std::collections::HashSet;
use std::io::{Cursor, Write};

use zip::CompressionMethod;
use zip::write::{SimpleFileOptions, ZipWriter};

/// Zips `files` (name, content) in order.
pub fn build(files: &[(String, Vec<u8>)]) -> Vec<u8> {
    let options = SimpleFileOptions::default().compression_method(CompressionMethod::Stored);
    let mut zip = ZipWriter::new(Cursor::new(Vec::new()));
    let mut taken = HashSet::new();
    for (name, content) in files {
        let name = unique_name(name, |n| taken.contains(n));
        zip.start_file(name.as_str(), options)
            .expect("writing to memory can't fail");
        zip.write_all(content)
            .expect("writing to memory can't fail");
        taken.insert(name);
    }
    zip.finish()
        .expect("writing to memory can't fail")
        .into_inner()
}

/// Name the app gives bundles, e.g. `blastqr-20261025-143000.zip`.
pub fn file_name() -> String {
    chrono::Local::now()
        .format("blastqr-%Y%m%d-%H%M%S.zip")
        .to_string()
}

/// `name`, or `name(1).ext`, `name(2).ext`… if taken. Same as the app's
/// `uniqueFileName`.
fn unique_name(name: &str, is_taken: impl Fn(&str) -> bool) -> String {
    if !is_taken(name) {
        return name.to_string();
    }
    let (base, ext) = match name.rfind('.') {
        Some(i) if i > 0 => name.split_at(i),
        _ => (name, ""),
    };
    (1..)
        .map(|n| format!("{base}({n}){ext}"))
        .find(|candidate| !is_taken(candidate))
        .unwrap()
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Read;

    #[test]
    fn stored_entries_with_unique_names() {
        let files = vec![
            ("a.txt".to_string(), b"one".to_vec()),
            ("a.txt".to_string(), b"two".to_vec()),
            (".env".to_string(), b"three".to_vec()),
            (".env".to_string(), b"four".to_vec()),
        ];
        let mut zip = zip::ZipArchive::new(Cursor::new(build(&files))).unwrap();
        let mut found = vec![];
        for i in 0..zip.len() {
            let mut entry = zip.by_index(i).unwrap();
            assert_eq!(entry.compression(), CompressionMethod::Stored);
            let mut content = String::new();
            entry.read_to_string(&mut content).unwrap();
            found.push((entry.name().unwrap().to_string(), content));
        }
        let expected = [
            ("a.txt", "one"),
            ("a(1).txt", "two"),
            (".env", "three"),
            (".env(1)", "four"),
        ];
        assert_eq!(found, expected.map(|(n, c)| (n.to_string(), c.to_string())));
    }

    #[test]
    fn bundle_name() {
        let name = file_name();
        assert!(name.starts_with("blastqr-") && name.ends_with(".zip"));
        assert_eq!(name.len(), "blastqr-20261025-143000.zip".len());
    }
}
