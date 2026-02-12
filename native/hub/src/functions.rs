use rinf::DartSignal;
use rinf::{RustSignalBinary, RustSignal, DartSignalBinary};
use raptorq::{Decoder, Encoder, EncodingPacket, ObjectTransmissionInformation};

use crate::signals::{DecodeChunkInput, DecodeError, DecodeProgress, StreamEncodeComplete};
use crate::signals::DecodeOutput;
use crate::signals::StreamEncodeInput;
use crate::signals::StreamEncodeConfig;
use crate::signals::StreamEncodeOutput;
use std::sync::{Arc, Mutex};
use once_cell::sync::Lazy;

#[derive(Default)]
struct EncodeState {
    config: Option<StreamEncodeConfig>,
}

static ENCODE_STATE: Lazy<Arc<Mutex<EncodeState>>> =
    Lazy::new(|| Arc::new(Mutex::new(EncodeState::default())));

pub async fn listen_for_config() {
    let receiver = StreamEncodeConfig::get_dart_signal_receiver();

    while let Some(dart_signal) = receiver.recv().await {
        let mut state = ENCODE_STATE.lock().unwrap();
        state.config = Some(dart_signal.message);

        rinf::debug_print!("Configuration set!");
    }
}

pub async fn stream_encode_data() {
    let receiver = StreamEncodeInput::get_dart_signal_receiver();

    while let Some(dart_signal) = receiver.recv().await {
        let state = ENCODE_STATE.lock().unwrap();
        let config = state
            .config
            .as_ref()
            .expect("StreamEncodeConfig must be sent first");

        let data = dart_signal.binary;

        let mtu = config.mtu as u16;

        // Create the Encoder
        let encoder = Encoder::with_defaults(&data, mtu);

        // Perform the encoding, and serialize to Vec<u8> for transmission
        let packets = encoder.get_encoded_packets(config.repair_packets_per_block);
        let last_index = packets.len() - 1; // Get last index

        for (index, packet) in packets.iter().enumerate() {
            StreamEncodeOutput {}.send_signal_to_dart(packet.serialize());
            if index == last_index {
                StreamEncodeComplete{}.send_signal_to_dart();
            }
        }
        rinf::debug_print!("All packets sent!");
    }
}

pub async fn decode_chunk() {
    let receiver= DecodeChunkInput::get_dart_signal_receiver();

    let mut decoder: Option<Decoder> = None;
    let mut mtu: i32 = 924;
    let mut transfer_length = 0;

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
            rinf::debug_print!("Configure decoder");
        }

        if let Some(ref mut dec) = decoder {
            if chunk.is_empty() {
                rinf::debug_print!("chunk is empty :(");
                DecodeError {
                    message: "empty chunk".to_owned()
                }.send_signal_to_dart();
                continue;
            }

            // Perform the decoding
            let result: Option<Vec<u8>> = dec.decode(EncodingPacket::deserialize(&chunk));

            if result.is_some() {
                rinf::debug_print!("Decode success!");
                DecodeOutput {}.send_signal_to_dart(result.unwrap());
                // Reset
                decoder = None;
                mtu = 0;
                transfer_length = 0;
            } else {
                DecodeProgress {
                    chunk_len: chunk.len() as i32,
                }.send_signal_to_dart();
            }
        }
    }
}
