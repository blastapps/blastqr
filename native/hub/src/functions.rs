use crate::messages::*;
use raptorq::{Decoder, Encoder, EncodingPacket, ObjectTransmissionInformation};
use std::time::Instant;

pub async fn encode_data() {
    let receiver = EncodeInput::get_dart_signal_receiver();

    while let Some(dart_signal) = receiver.recv().await {
        let message: EncodeInput = dart_signal.message;

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
                    chunk_len: 0,
                }
                .send_signal_to_dart();
                continue;
            }

            // Perform the decoding
            let result: Option<Vec<u8>> = dec.decode(EncodingPacket::deserialize(&chunk));

            let elapsed = start.elapsed();
            if result.is_some() {
                rinf::debug_print!("Decode success!");
                DecodeOutput {
                    result: result.unwrap(),
                    time: elapsed.as_millis() as i32,
                    chunk_len: 0,
                }
                .send_signal_to_dart();
                // Reset
                decoder = None;
                mtu = 0;
                transfer_length = 0;
            } else {
                DecodeOutput {
                    result: [].to_vec(),
                    time: elapsed.as_millis() as i32,
                    chunk_len: chunk.len() as i32,
                }
                .send_signal_to_dart();
            }
        }
    }
}
