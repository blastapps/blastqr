import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:raptorq_flutter/raptorq_flutter.dart';

/// An endless stream of RaptorQ packets for one transfer.
///
/// All source packets come first (the original data, in order), then new
/// repair packets forever, interleaved across blocks. Every packet is
/// different, so a receiver never sees a frame it already has. Repair ids are
/// 24-bit, so after ~16 million repair packets per block the stream wraps
/// around and starts repeating, which takes days at any realistic fps.
class RaptorqStreamingEncoder {
  final int mtu;

  late final RaptorQEncoder _encoder;
  late final int _sourceCount;
  late final int _blockCount;
  late final int _maxRepair;

  int _nextSource = 0;
  int _nextRepair = 0;

  RaptorqStreamingEncoder({required this.mtu});

  Future<void> init(Uint8List data) async {
    _encoder = await RaptorQEncoder.newInstance(data: data, mtu: mtu);
    _sourceCount = _encoder.sourcePacketCount();
    _blockCount = _encoder.oti().sourceBlocks;
    _maxRepair = _encoder.maxRepairPackets();
  }

  /// Number of source packets (K, summed over all blocks).
  int get sourceCount => _sourceCount;

  /// Returns the next packets of the stream: about [count], at least one.
  Future<List<Uint8List>> nextPackets(int count) async {
    if (_nextSource < _sourceCount) {
      final n = math.min(count, _sourceCount - _nextSource);
      final packets = await _encoder.sourcePackets(
        start: _nextSource,
        count: n,
      );
      _nextSource += n;
      return packets;
    }

    // One "round" is one repair packet for every block.
    final rounds = math.min(
      math.max(1, (count / _blockCount).ceil()),
      _maxRepair - _nextRepair,
    );
    final packets = await _encoder.repairPackets(
      start: _nextRepair,
      count: rounds,
    );
    _nextRepair = (_nextRepair + rounds) % _maxRepair;
    return packets;
  }

  void dispose() {
    _encoder.dispose();
  }
}
