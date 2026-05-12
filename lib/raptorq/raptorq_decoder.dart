import 'dart:async';

import 'package:flutter/services.dart';
import 'package:raptorq_flutter/raptorq_flutter.dart';

class RaptorqDecoder {
  final Function(int chunkLen, int totalChunks, double estimatedProgress)?
  onProcessChunk;
  final Function()? onTransferComplete;
  final Function(Uint8List result) onReceiveResult;

  RaptorQDecoder? _decoder;

  bool complete = false;
  bool isLoadingResult = false;
  int count = 0;
  double estimatedProgress = 0;
  Uint8List latestResult = Uint8List(0);

  RaptorqDecoder({
    required this.onReceiveResult,
    this.onTransferComplete,
    this.onProcessChunk,
  });

  Future<RaptorQDecoder> _buildDecoder(int transferLength, int mtu) async {
    final oti = await ObjectTransmissionInfo.withDefaults(
      transferLength: BigInt.from(transferLength),
      maxPacketSize: mtu,
    );
    return RaptorQDecoder.newInstance(oti: oti);
  }

  Future<void> decodeChunk(Uint8List data, int transferLength, int mtu) async {
    if (complete || isLoadingResult) {
      return;
    }

    _decoder ??= await _buildDecoder(transferLength, mtu);

    final result = await _decoder!.addPacket(packet: data);

    if (result != null) {
      _handleOutput(result);
      return;
    }

    count += 1;

    final chunkLen = data.length;
    estimatedProgress = (count * mtu) / (transferLength * 1.25);
    onProcessChunk?.call(chunkLen, count, estimatedProgress);
  }

  void _handleOutput(Uint8List bytes) {
    if (bytes.isNotEmpty && !complete) {
      latestResult = bytes;
      complete = true;
      onReceiveResult(latestResult);
    }
  }

  void reset() {
    count = 0;
    estimatedProgress = 0;
    complete = false;
    isLoadingResult = false;
    latestResult = Uint8List(0);
    _decoder?.dispose();
    _decoder = null;
  }

  void dispose() {
    _decoder?.dispose();
  }
}
