import 'dart:async';
import 'dart:developer';

import 'package:blast_qr/src/bindings/signals/signals.dart';
import 'package:flutter/services.dart';

class RaptorqDecoder {
  final Function(int chunkLen, int totalChunks, double estimatedProgress)?
  onProcessChunk;
  final Function()? onTransferComplete;
  final Function(Uint8List result) onReceiveResult;

  bool complete = false;
  bool isLoadingResult = false;
  int count = 0;
  double estimatedProgress = 0;
  Uint8List latestResult = Uint8List(0);

  RaptorqDecoder({
    required this.onReceiveResult,
    this.onTransferComplete,
    this.onProcessChunk,
  }) {
    _listenForResult();
  }

  void _listenForResult() {
    DecodeOutput.rustSignalStream.listen((signal) {
      _handleOutput(signal.binary);
    });
  }

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

    try {
      final result = await DecodeProgress.rustSignalStream.first
          .then((progress) {
            return _ProgressResult(progress.message);
          })
          .timeout(const Duration(milliseconds: 400));

      final chunkLen = result.progress.chunkLen;
      estimatedProgress = (count * mtu) / (transferLength * 1.25);
      onProcessChunk?.call(chunkLen, count, estimatedProgress);
    } on TimeoutException {
      isLoadingResult = true;
      _waitForResult();
    } catch (e) {
      log('decodeChunk error: $e');
    }
  }

  void _waitForResult() async {
    log('Waiting for result...');
    onTransferComplete?.call();
    try {
      final completionSignal = await DecodeOutput.rustSignalStream.first
          .timeout(const Duration(milliseconds: 400));

      final binaryResult = completionSignal.binary;
      _handleOutput(binaryResult);
    } catch (e) {
      log(e.toString());
      return;
    }
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
  }
}

sealed class _DecodeResult {}

class _ProgressResult extends _DecodeResult {
  final DecodeProgress progress;
  _ProgressResult(this.progress);
}
