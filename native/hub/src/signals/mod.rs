use rinf::{DartSignal,RustSignal,RustSignalBinary, DartSignalBinary};
use serde::{Deserialize, Serialize};


#[derive(Deserialize, DartSignal)]
pub struct StreamEncodeConfig {
    pub mtu: i32,
    pub repair_packets_per_block: u32
}

#[derive(Deserialize, DartSignalBinary)]
pub struct StreamEncodeInput {}

#[derive(Serialize, RustSignalBinary)]
pub struct StreamEncodeOutput {}

#[derive(Serialize, RustSignal)]
pub struct StreamEncodeComplete {}

#[derive(Deserialize, DartSignal)]
pub struct DecodeChunkInput { 
    pub data: Vec<u8>,
    pub mtu: i32,
    pub transfer_length: i32,
    pub reset: bool,
}

#[derive(Serialize, RustSignalBinary)]
pub struct DecodeOutput {}

#[derive(Serialize, RustSignal)]
pub struct DecodeProgress {
    pub chunk_len: i32
}

#[derive(Serialize, RustSignal)]
pub struct DecodeComplete {
    pub time: i32
}

#[derive(Serialize, RustSignal)]
pub struct DecodeError {
    pub message: String
}

