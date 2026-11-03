//! The endless packet stream: all source packets block by block, then new
//! repair packets forever, one per block in turn.

use std::collections::VecDeque;

use raptorq::{Encoder, extended_source_block_symbols, partition};

/// Repair packets generated per batch, across all blocks.
const REPAIR_BATCH: usize = 32;

pub struct PacketStream {
    encoder: Encoder,
    block_count: usize,
    next_source_block: usize,
    next_repair: u32,
    max_repair: u32,
    ready: VecDeque<Vec<u8>>,
}

impl PacketStream {
    pub fn new(data: &[u8], symbol_size: u16) -> PacketStream {
        let encoder = Encoder::with_defaults(data, symbol_size);
        let largest_block = block_sizes(&encoder).into_iter().max().unwrap_or(0);
        PacketStream {
            block_count: encoder.get_block_encoders().len(),
            max_repair: (1 << 24) - extended_source_block_symbols(largest_block),
            encoder,
            next_source_block: 0,
            next_repair: 0,
            ready: VecDeque::new(),
        }
    }

    /// Number of source packets (K, summed over blocks). The receiver needs
    /// about this many frames.
    pub fn source_count(&self) -> u32 {
        block_sizes(&self.encoder).iter().sum()
    }

    pub fn symbol_size(&self) -> u16 {
        self.encoder.get_config().symbol_size()
    }

    fn refill(&mut self) {
        let blocks = self.encoder.get_block_encoders();
        if self.next_source_block < self.block_count {
            let block = &blocks[self.next_source_block];
            self.ready
                .extend(block.source_packets().into_iter().map(|p| p.serialize()));
            self.next_source_block += 1;
            return;
        }
        let rounds = (REPAIR_BATCH / self.block_count)
            .max(1)
            .min((self.max_repair - self.next_repair) as usize) as u32;
        let per_block: Vec<_> = blocks
            .iter()
            .map(|b| b.repair_packets(self.next_repair, rounds))
            .collect();
        for i in 0..rounds as usize {
            for block in &per_block {
                self.ready.push_back(block[i].serialize());
            }
        }
        self.next_repair = (self.next_repair + rounds) % self.max_repair;
    }
}

impl Iterator for PacketStream {
    type Item = Vec<u8>;

    fn next(&mut self) -> Option<Vec<u8>> {
        if self.ready.is_empty() {
            self.refill();
        }
        self.ready.pop_front()
    }
}

fn block_sizes(encoder: &Encoder) -> Vec<u32> {
    let config = encoder.get_config();
    let kt = config
        .transfer_length()
        .div_ceil(config.symbol_size() as u64);
    let (kl, ks, zl, zs) = partition(kt as u32, config.source_blocks());
    let mut sizes = vec![kl; zl as usize];
    sizes.extend(vec![ks; zs as usize]);
    sizes
}

#[cfg(test)]
mod tests {
    use super::*;
    use raptorq::{Decoder, EncodingPacket};

    #[test]
    fn source_first_then_interleaved_repair() {
        let data: Vec<u8> = (0..10_000u32).map(|i| (i * 7) as u8).collect();
        let mut stream = PacketStream::new(&data, 96);
        let k = stream.source_count() as usize;
        let packets: Vec<_> = stream.by_ref().take(k + 5).collect();
        // ESI of the first repair packet equals K for a single block.
        let esi = |p: &[u8]| u32::from_be_bytes([0, p[1], p[2], p[3]]);
        assert_eq!(esi(&packets[0]), 0);
        assert_eq!(esi(&packets[k - 1]), k as u32 - 1);
        assert!(esi(&packets[k]) >= k as u32);

        // Repair only, skipping all source packets, still decodes.
        let mut decoder = Decoder::new(stream.encoder.get_config());
        let mut out = None;
        for p in packets[k..].iter().cloned().chain(stream) {
            out = decoder.decode(EncodingPacket::deserialize(&p));
            if out.is_some() {
                break;
            }
        }
        assert_eq!(out.unwrap(), data);
    }
}
