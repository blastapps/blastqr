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
      final result = await Future.any([
        // Progress path
        DecodeProgress.rustSignalStream.first.then((progress) {
          return _ProgressResult(progress.message);
        }),

        // Completion path
        Future.wait([
          DecodeOutput.rustSignalStream.first,
          DecodeComplete.rustSignalStream.first,
        ]).then((values) {
          return _CompletionResult(
            binary: values[0].binary,
            time: (values[1].message as DecodeComplete).time,
          );
        }),
      ]).timeout(const Duration(milliseconds: 400));

      if (result is _ProgressResult) {
        final chunkLen = result.progress.chunkLen;
        estimatedProgress = (count * mtu) / (transferLength * 1.25);
        onProcessChunk?.call(chunkLen, count, estimatedProgress);
        return;
      }

      if (result is _CompletionResult) {
        _handleOutput(result.binary, result.time);
        return;
      }
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
      final completionSignals = await Future.wait([
        DecodeOutput.rustSignalStream.first,
        DecodeComplete.rustSignalStream.first,
      ]).timeout(const Duration(milliseconds: 400));

      final binaryResult = completionSignals[0].binary;
      final timeResult = completionSignals[1].message as DecodeComplete;
      _handleOutput(binaryResult, timeResult.time);
    } catch (e) {
      log(e.toString());
      return;
    }
  }

  void _handleOutput(Uint8List bytes, int time) {
    if (bytes.isNotEmpty && !complete) {
      latestResult = bytes;
      elapsedTime = time;
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

sealed class _DecodeResult {}

class _ProgressResult extends _DecodeResult {
  final DecodeProgress progress;
  _ProgressResult(this.progress);
}

class _CompletionResult extends _DecodeResult {
  final Uint8List binary;
  final int time;
  _CompletionResult({required this.binary, required this.time});
}
