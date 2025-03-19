import 'dart:async';
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:blast_qr/messages/basic.pb.dart';

class RaptorqDecoder {
  final Function(int chunkLen, int totalChunks, double estimatedProgress)?
  onProcessChunk;
  final Function()? onTransferComplete;
  final Function(Uint8List result) onReceiveResult;

  bool complete = false;
  bool isLoadingResult = false;
  int elapsedTime = 0;
  int count = 0;
  double estimatedProgress = 0;
  Uint8List latestResult = Uint8List(0);

  RaptorqDecoder({
    required this.onReceiveResult,
    this.onTransferComplete,
    this.onProcessChunk,
  });

  Future<void> decodeChunk(Uint8List data, int transferLength, int mtu) async {
    if (complete || isLoadingResult) {
      return;
    }

    DecodeChunkInput(
      data: data,
      mtu: mtu,
      transferLength: transferLength,
      reset: count == 0,
    ).sendSignalToRust();

    count += 1;
    log('Decoding $count');

    try {
      final signal = await DecodeOutput.rustSignalStream.first.timeout(
        const Duration(milliseconds: 100),
        onTimeout: () {
          isLoadingResult = true;
          _waitForResult();
          throw TimeoutException("Signal stream timed out");
        },
      );
      final msg = signal.message;
      final bytes = msg.result;
      if (bytes.isNotEmpty && !complete) {
        onTransferComplete?.call();
        _handleOutput(msg);
      } else {
        estimatedProgress = (count * mtu) / (transferLength * 1.25);
        onProcessChunk?.call(msg.chunkLen, count, estimatedProgress);
      }
    } catch (e) {
      log(e.toString());
      return;
    }
  }

  void _waitForResult() async {
    log('Waiting for result...');
    onTransferComplete?.call();
    try {
      final signal = await DecodeOutput.rustSignalStream.first.timeout(
        const Duration(seconds: 30),
      );
      final msg = signal.message;
      _handleOutput(msg);
    } catch (e) {
      log(e.toString());
      return;
    }
  }

  void _handleOutput(DecodeOutput output) {
    final bytes = output.result;
    if (bytes.isNotEmpty && !complete) {
      latestResult = bytes as Uint8List;
      elapsedTime = output.time;
      log('Complete in $elapsedTime ms!');
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
  }
}
