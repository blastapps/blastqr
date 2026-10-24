import 'dart:async';
import 'dart:typed_data';

import 'package:raptorq_flutter/raptorq_flutter.dart';

class RaptorqStreamingEncoder {
  /// Extra repair packets, as a fraction of each block's source packets.
  final double redundancy;
  final int mtu;

  late RaptorQEncoder _encoder;

  RaptorqStreamingEncoder({required this.redundancy, required this.mtu});

  Future<List<Uint8List>> encode(Uint8List data) async {
    _encoder = await RaptorQEncoder.newInstance(data: data, mtu: mtu);
    final oti = _encoder.oti();
    final repairPackets = repairPacketsPerBlock(
      transferLength: data.length,
      symbolSize: oti.symbolSize,
      sourceBlocks: oti.sourceBlocks,
      redundancy: redundancy,
    );
    return _encoder.getEncodedPackets(repairPacketsPerBlock: repairPackets);
  }

  void dispose() {
    _encoder.dispose();
  }

  /// Repair packets to generate for each source block.
  ///
  /// RaptorQ applies the count to every block, so it must be based on the
  /// size of one block, not the whole file. Large files are split into
  /// several blocks (above ~165 MB at the default MTU), and sizing by the
  /// whole file would multiply the repair frames by the number of blocks.
  /// Uses the largest block, since blocks differ by at most one symbol.
  static int repairPacketsPerBlock({
    required int transferLength,
    required int symbolSize,
    required int sourceBlocks,
    required double redundancy,
  }) {
    final totalSymbols = (transferLength / symbolSize).ceil();
    final largestBlock = (totalSymbols / sourceBlocks).ceil();
    return (largestBlock * redundancy).ceil();
  }
}
