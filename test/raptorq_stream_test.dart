// End-to-end tests of the endless sender stream and the receiver's decoder,
// using the real RaptorQ library built for this machine. Build it first:
//   (cd ../raptorq_flutter/rust && cargo build --release)
import 'dart:io';
import 'dart:math';

import 'package:blast_qr/model/blast_qrcode_data.dart';
import 'package:blast_qr/raptorq/raptorq_decoder.dart';
import 'package:blast_qr/raptorq/raptorq_streaming_encoder.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raptorq_flutter/src/rust/frb_generated.dart';

const _libraryPath =
    '../raptorq_flutter/rust/target/release/librust_lib_raptorq_dart.dylib';

final _skip =
    File(_libraryPath).existsSync()
        ? false
        : 'RaptorQ library not built (see top of file)';

Uint8List _data(int length) =>
    Uint8List.fromList(List.generate(length, (i) => (i * 31 + 7) % 251));

/// Wraps a packet in a v2 frame, like the sender does.
BlastQrcodeData _frame(Uint8List packet, int transferLength) {
  final header = BlastQrcodeData.buildHeader(
    flags: 0,
    kind: BlastQrcodeData.kindFile,
    sessionId: 7,
    transferLength: transferLength,
    symbolSize: packet.length - BlastQrcodeData.packetIdLength,
  );
  return BlastQrcodeData.parse(
    Uint8List.fromList([...header, ...packet]),
  ).frame!;
}

/// Feeds the endless stream to a decoder, keeping each frame with
/// probability [catchRate]. Returns how many frames were shown.
Future<int> _transfer(
  Uint8List data, {
  required int mtu,
  required double catchRate,
  int maxFrames = 100000,
}) async {
  final encoder = RaptorqStreamingEncoder(mtu: mtu);
  await encoder.init(data);
  Uint8List? result;
  final decoder = RaptorqDecoder(onReceiveResult: (r) => result = r);
  final random = Random(42);
  var shown = 0;
  try {
    while (result == null && shown < maxFrames) {
      for (final packet in await encoder.nextPackets(32)) {
        shown++;
        if (random.nextDouble() < catchRate) {
          await decoder.decodeChunk(_frame(packet, data.length));
          if (result != null) break;
        }
      }
    }
  } finally {
    encoder.dispose();
    decoder.dispose();
  }
  expect(result, data);
  return shown;
}

void main() {
  setUpAll(() async {
    if (_skip != false) return;
    await RustLib.init(externalLibrary: ExternalLibrary.open(_libraryPath));
  });

  test('source packets come first, then new repair packets', () async {
    final data = _data(20000);
    final encoder = RaptorqStreamingEncoder(mtu: 1000);
    await encoder.init(data);
    expect(encoder.sourceCount, 20);

    // Payload id: block number + 24-bit symbol id.
    final ids = <int>[];
    for (var i = 0; i < 10; i++) {
      for (final p in await encoder.nextPackets(8)) {
        ids.add((p[0] << 24) | (p[1] << 16) | (p[2] << 8) | p[3]);
      }
    }
    encoder.dispose();
    // The first 20 are the source packets, in order.
    expect(ids.take(20), List.generate(20, (i) => i));
    expect(ids.length, greaterThan(20));
    expect(ids.toSet().length, ids.length, reason: 'no packet repeats');
  }, skip: _skip);

  test('decodes with no loss using about K frames', () async {
    final shown = await _transfer(_data(200000), mtu: 2935, catchRate: 1);
    expect(shown, lessThanOrEqualTo(69 + 2));
  }, skip: _skip);

  test('heavy loss: 30% catch rate needs ~K/0.3 frames, no repeats', () async {
    final shown = await _transfer(_data(200000), mtu: 2935, catchRate: 0.3);
    // K = 69. A looping list of 1.64·K frames would need far more.
    expect(shown, lessThan(69 / 0.3 * 1.3));
  }, skip: _skip);

  test(
    'works across several source blocks',
    () async {
      // 96-byte symbols: ~6.5 MB spans 2 blocks.
      final shown = await _transfer(
        _data(6500000),
        mtu: 100,
        catchRate: 0.5,
        maxFrames: 300000,
      );
      expect(shown, greaterThan(0));
    },
    skip: _skip,
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test('repeated reads of the same code are not counted', () async {
    final data = _data(50000);
    final encoder = RaptorqStreamingEncoder(mtu: 2935);
    await encoder.init(data);
    final decoder = RaptorqDecoder(onReceiveResult: (_) {});
    try {
      final packets = await encoder.nextPackets(3);
      // Each code read three times, as a camera faster than the display would.
      for (final packet in packets) {
        for (var read = 0; read < 3; read++) {
          final used = await decoder.decodeChunk(_frame(packet, data.length));
          expect(used, read == 0, reason: 'only the first read is used');
        }
      }
      expect(decoder.count, 3);
      expect(decoder.estimatedProgress, closeTo(3 / 18, 0.001)); // K = 18
    } finally {
      encoder.dispose();
      decoder.dispose();
    }
  }, skip: _skip);
}
