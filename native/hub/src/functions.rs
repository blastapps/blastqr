use crate::messages::*;
use raptorq::{Decoder, Encoder, EncodingPacket, ObjectTransmissionInformation};
use std::time::Instant;

pub async fn stream_encode_data() {
    let receiver = StreamEncodeInput::get_dart_signal_receiver();

    while let Some(dart_signal) = receiver.recv().await {
        let message: StreamEncodeInput = dart_signal.message;

        let data = message.data;
        let mtu = message.mtu as u16;

        // Create the Encoder
        let encoder = Encoder::with_defaults(&data, mtu);

        // Perform the encoding, and serialize to Vec<u8> for transmission
        let packets = encoder.get_encoded_packets(message.repair_packets_per_block);
        let last_index = packets.len() - 1; // Get last index

        for (index, packet) in packets.iter().enumerate() {
            StreamEncodeOutput {
                result: packet.serialize(),
                is_complete: index == last_index, // True on last iteration
            }
            .send_signal_to_dart();
        }
        rinf::debug_print!("All packets sent!");
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
