import 'dart:async';
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:blast_qr/messages/basic.pb.dart';

class RaptorqDecoder {
  final int mtu;
  final Function(int chunks, String speed)? onProcessChunk;
  final Function()? onTransferComplete;
  final Function(Uint8List result) onReceiveResult;

  bool complete = false;
  bool isLoadingResult = false;
  int elapsedTime = 0;
  int count = 0;
  Uint8List latestResult = Uint8List(0);

  RaptorqDecoder({
    required this.mtu,
    required this.onReceiveResult,
    this.onTransferComplete,
    this.onProcessChunk,
  });

  Future<void> decodeChunk(Uint8List data, int transferLength) async {
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
        _handleOutput(msg);
      } else {
        final speed = (msg.bytesProcessed / 1000) / (msg.time / 1000);
        final formattedSpeed = '${speed.toStringAsFixed(1)}kB/s';
        log(
          'Processed: ${msg.bytesProcessed}/$transferLength Time: ${msg.time} Speed: $formattedSpeed',
        );
        onProcessChunk?.call(count, formattedSpeed);
        HapticFeedback.lightImpact();
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
    complete = false;
    isLoadingResult = false;
    latestResult = Uint8List(0);
  }
}
