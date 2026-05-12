// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:typed_data';

import 'package:raptorq_flutter/raptorq_flutter.dart';

class RaptorqStreamingEncoder {
  final int repairPacketsPerBlock;
  final int mtu;

  late RaptorQEncoder _encoder;

  RaptorqStreamingEncoder({
    required this.repairPacketsPerBlock,
    required this.mtu,
  });

  Future<List<Uint8List>> encode(Uint8List data) async {
    _encoder = await RaptorQEncoder.newInstance(data: data, mtu: mtu);
    return _encoder.getEncodedPackets(
      repairPacketsPerBlock: repairPacketsPerBlock,
    );
  }

  void dispose() {
    _encoder.dispose();
  }
}
