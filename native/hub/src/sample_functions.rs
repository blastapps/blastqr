//! This module is written for Rinf demonstrations.
use crate::messages::*;
use rand::seq::SliceRandom;
use raptorq::{Decoder, Encoder, EncodingPacket, ObjectTransmissionInformation};
use std::str;
use std::time::Instant;

pub async fn communicate() {
    // Send signals to Dart like below.
    SmallNumber { number: 7 }.send_signal_to_dart();

    // Get receivers that listen to Dart signals like below.
    let receiver = SmallText::get_dart_signal_receiver();
    while let Some(dart_signal) = receiver.recv().await {
        let message: SmallText = dart_signal.message;
        rinf::debug_print!("{message:?}");
    }
}

pub async fn encode_data() {
    let receiver = EncodeInput::get_dart_signal_receiver();

    while let Some(dart_signal) = receiver.recv().await {
        let message: EncodeInput = dart_signal.message;
        rinf::debug_print!("{message:?}");

        let data = message.data;
        let mtu = message.mtu as u16;

        // Create the Encoder
        let encoder = Encoder::with_defaults(&data, mtu);

        // Perform the encoding, and serialize to Vec<u8> for transmission
        let packets: Vec<Vec<u8>> = encoder
            .get_encoded_packets(message.repair_packets_per_block)
            .iter()
            .map(|packet| packet.serialize())
            .collect();

        let length = packets.len();
        rinf::debug_print!("Encoded packet count: {length:?}");

        EncodeOutput { result: packets }.send_signal_to_dart(); // GENERATED
    }
}

pub async fn decode_chunk() {
    let receiver: rinf::SignalReceiver<rinf::DartSignal<DecodeChunkInput>> =
        DecodeChunkInput::get_dart_signal_receiver();

    let mut decoder: Option<Decoder> = None;
    let mut mtu: i32 = 924;
    let mut transfer_length = 0;
    let mut bytes_processed = 0;
    let mut start = Instant::now();

    while let Some(dart_signal) = receiver.recv().await {
        let msg: DecodeChunkInput = dart_signal.message;
        let chunk: Vec<u8> = msg.data;

        if decoder == None
            || msg.mtu != mtu
            || msg.transfer_length != transfer_length
            || msg.reset == true
        {
            let config = ObjectTransmissionInformation::with_defaults(
                msg.transfer_length as u64,
                msg.mtu as u16,
            );
            decoder = Some(Decoder::new(config));
            mtu = msg.mtu;
            transfer_length = msg.transfer_length;
            start = Instant::now();
            rinf::debug_print!("Configure decoder");
        }

        if let Some(ref mut dec) = decoder {
            if chunk.is_empty() {
                rinf::debug_print!("chunk is empty :(");
                DecodeOutput {
                    result: [].to_vec(),
                    time: 0,
                    bytes_processed: 0,
                }
                .send_signal_to_dart();
                continue;
            }
            //let len = msg.transfer_length;
            //rinf::debug_print!("Decoding chunk from rust: {len:?}");

            // Perform the decoding
            let elapsed = start.elapsed();

            rinf::debug_print!("Before decode {elapsed:?}");
            let result = dec.decode(EncodingPacket::deserialize(&chunk));

            let elapsed = start.elapsed();
            rinf::debug_print!("After decode {elapsed:?}");

            if result.is_some() {
                rinf::debug_print!("Decode success!");
                DecodeOutput {
                    result: result.unwrap(),
                    time: elapsed.as_millis() as i32,
                    bytes_processed: bytes_processed,
                }
                .send_signal_to_dart();
                // Reset
                decoder = None;
                mtu = 0;
                transfer_length = 0;
                bytes_processed = 0;
            } else {
                bytes_processed += chunk.len() as i32;
                DecodeOutput {
                    result: [].to_vec(),
                    time: elapsed.as_millis() as i32,
                    bytes_processed: bytes_processed,
                }
                .send_signal_to_dart();
            }
        }
    }
}

pub async fn run_demo() {
    let receiver = DemoInput::get_dart_signal_receiver();

    let mut decoder: Option<Decoder> = None;

    while let Some(dart_signal) = receiver.recv().await {
        let message = dart_signal.message;
        let mtu = message.mtu as u16;
        let t_len = message.transfer_length as u64;
        let data = message.data;

        rinf::debug_print!("Configure encoder with: {mtu:?} / {t_len:?}");

        // Create the Encoder, with an MTU of 1400 (common for Ethernet)
        let encoder = Encoder::with_defaults(&data, mtu);

        // Perform the encoding, and serialize to Vec<u8> for transmission
        let mut packets: Vec<Vec<u8>> = encoder
            .get_encoded_packets(15)
            .iter()
            .map(|packet| packet.serialize())
            .collect();

        // Here we simulate losing 10 of the packets randomly. Normally, you would send them over
        // (potentially lossy) network here.
        packets.shuffle(&mut rand::thread_rng());
        // Erase 10 packets at random
        let length = packets.len();
        rinf::debug_print!("Generated packet count: {length:?}");

        packets.truncate(length - 10);

        // Perform the decoding
        let mut result = None;
        while !packets.is_empty() {
            if decoder == None {
                let mtu = message.mtu as u16;
                let config = ObjectTransmissionInformation::with_defaults(
                    message.transfer_length as u64,
                    mtu,
                );
                decoder = Some(Decoder::new(config));
                rinf::debug_print!("Configure decoder with: {mtu:?} / {t_len:?}");
            }

            if let Some(ref mut dec) = decoder {
                result = dec.decode(EncodingPacket::deserialize(&packets.pop().unwrap()));
                if result.is_some() {
                    break;
                }
            }
        }

        // Check that even though some of the data was lost we are able to reconstruct the original message
        if result.unwrap() == data {
            rinf::debug_print!("message reconstruction success");
            let s = match str::from_utf8(&data) {
                Ok(v) => v,
                Err(e) => panic!("Invalid UTF-8 sequence: {}", e),
            };

            rinf::debug_print!("result: {s:?}");
        } else {
            rinf::debug_print!("message reconstruction FAIL");
        }
    }
}

/*
pub async fn decode_data() {
    let receiver = DecodeInput::get_dart_signal_receiver();

    while let Some(dart_signal) = receiver.recv().await {
        let message = dart_signal.message;
        let mut packets = message.data;
        let mtu = message.mtu as u16;

        let config = ObjectTransmissionInformation::with_defaults(
            message.transfer_length as u64,
            mtu,
        );
        let mut decoder = Decoder::new(config);

        // Perform the decoding
        let mut result = None;
        while !packets.is_empty() {
            result = decoder.decode(EncodingPacket::deserialize(&packets.pop().unwrap()));
            if result.is_some() {
                break;
            }
        }

        DecodeOutput { result: result.unwrap() }.send_signal_to_dart();
    }
}
*/

// Though async tasks work, using the actor model
// is highly recommended for state management
// to achieve modularity and scalability in your app.
// To understand how to use the actor model,
// refer to the Rinf documentation.
