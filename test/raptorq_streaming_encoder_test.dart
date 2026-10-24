import 'package:blast_qr/raptorq/raptorq_streaming_encoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('repairPacketsPerBlock', () {
    int repair(int transferLength, int symbolSize, int sourceBlocks) =>
        RaptorqStreamingEncoder.repairPacketsPerBlock(
          transferLength: transferLength,
          symbolSize: symbolSize,
          sourceBlocks: sourceBlocks,
          redundancy: 0.64,
        );

    test('single block: 64% of the source packets', () {
      // 100 symbols of 2928 bytes.
      expect(repair(100 * 2928, 2928, 1), 64);
    });

    test('several blocks: based on one block, not the whole file', () {
      // 1M symbols in 18 blocks → largest block has 55,556 symbols.
      final perBlock = repair(1000000 * 96, 96, 18);
      expect(perBlock, (55556 * 0.64).ceil());

      // Total extra frames stay ~64% of the file, not 18 × 64%.
      final totalRepair = perBlock * 18;
      expect(totalRepair / 1000000, closeTo(0.64, 0.01));
    });

    test('tiny files still get at least one repair packet', () {
      expect(repair(500, 2928, 1), 1);
    });
  });
}
