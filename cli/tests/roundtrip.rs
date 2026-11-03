//! Sends a file through rendered QR codes and receives it the way the app
//! does, with an independent QR decoder.

use std::io::Read;

use blastqr::protocol::{self, TransferObject};
use blastqr::qr::{self, Matrix};
use blastqr::stream::PacketStream;
use blastqr::{envelope, password};
use raptorq::{Decoder, EncodingPacket, ObjectTransmissionInformation};

/// Draws the matrix with a 4-module quiet zone and scans it back.
fn scan(m: &Matrix) -> Vec<u8> {
    const PX: usize = 3;
    let side = (m.size + 8) * PX;
    let mut img = rqrr::PreparedImage::prepare_from_greyscale(side, side, |x, y| {
        let (r, c) = ((y / PX) as isize - 4, (x / PX) as isize - 4);
        let inside = r >= 0 && c >= 0 && (r as usize) < m.size && (c as usize) < m.size;
        if inside && m.is_dark(r as usize, c as usize) {
            0
        } else {
            255
        }
    });
    let grids = img.detect_grids();
    assert_eq!(grids.len(), 1);
    let mut bytes = Vec::new();
    grids[0].decode_to(&mut bytes).expect("QR decodes");
    bytes
}

fn send_and_receive(content: &[u8], name: &str, code: Option<&str>, symbol_size: usize) {
    let transfer = TransferObject::build(name, false, content, true, code);
    let len = transfer.bytes.len();
    let header = protocol::frame_header(transfer.flags(), 4242, len as u32, symbol_size as u16);
    let version = qr::version_for(symbol_size + protocol::FRAME_OVERHEAD).unwrap();
    let stream = PacketStream::new(&transfer.bytes, symbol_size as u16);
    let k = stream.source_count() as usize;

    // Receiver side, as in the app.
    let mut decoder: Option<Decoder> = None;
    let mut received = None;
    // Lose every third frame; repair packets make up for it.
    for (i, packet) in stream.enumerate().take(3 * k + 20) {
        if i % 3 == 1 {
            continue;
        }
        let mut frame = header.to_vec();
        frame.extend_from_slice(&packet);
        let scanned = scan(&qr::encode(&frame, version));
        assert_eq!(scanned, frame);

        assert_eq!(&scanned[0..3], b"bQR");
        assert_eq!(scanned[3], protocol::PROTOCOL_VERSION);
        let transfer_len = u32::from_be_bytes(scanned[8..12].try_into().unwrap()) as u64;
        let t = u16::from_be_bytes([scanned[12], scanned[13]]);
        assert_eq!(scanned.len(), 14 + 4 + t as usize);
        let decoder = decoder.get_or_insert_with(|| {
            Decoder::new(ObjectTransmissionInformation::with_defaults(
                transfer_len,
                t,
            ))
        });
        received = decoder.decode(EncodingPacket::deserialize(&scanned[14..]));
        if received.is_some() {
            break;
        }
    }
    let mut object = received.expect("transfer completes");

    let flags = header[4];
    if flags & protocol::FLAG_ENCRYPTED != 0 {
        object = envelope::decrypt(&object, &password::normalize(code.unwrap())).unwrap();
    }
    if flags & protocol::FLAG_GZIP != 0 {
        let mut plain = Vec::new();
        flate2::read::GzDecoder::new(&object[..])
            .read_to_end(&mut plain)
            .unwrap();
        object = plain;
    }
    let meta_len = u16::from_be_bytes([object[0], object[1]]) as usize;
    let meta = &object[2..2 + meta_len];
    assert_eq!(meta[0], protocol::TAG_FILE_NAME);
    let name_len = u16::from_be_bytes([meta[1], meta[2]]) as usize;
    assert_eq!(&meta[3..3 + name_len], name.as_bytes());
    assert_eq!(&object[2 + meta_len..], content);
}

fn noise(len: usize) -> Vec<u8> {
    let mut x = 0x2545F491u32;
    (0..len)
        .map(|_| {
            x ^= x << 13;
            x ^= x >> 17;
            x ^= x << 5;
            x as u8
        })
        .collect()
}

#[test]
fn plain_incompressible_file() {
    send_and_receive(&noise(5_000), "noise.bin", None, 296);
}

#[test]
fn gzipped_and_encrypted() {
    let text = "BlastQR terminal sender. ".repeat(400);
    let code = password::generate();
    // Typed loosely by the receiver.
    send_and_receive(
        text.as_bytes(),
        "notes.txt",
        Some(&code.to_lowercase()),
        200,
    );
}

#[test]
fn version_40_frames_scan() {
    send_and_receive(&noise(9_000), "big.bin", None, protocol::MAX_SYMBOL_SIZE);
}
