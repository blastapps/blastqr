import 'dart:async';

import 'package:blast_qr/model/blast_qrcode_data.dart';
import 'package:flutter/foundation.dart';
import 'package:raptorq_flutter/raptorq_flutter.dart';

class RaptorqDecoder {
  final Function(int chunkLen, int totalChunks, double estimatedProgress)?
  onProcessChunk;
  final Function()? onTransferComplete;
  final Function(Uint8List result) onReceiveResult;

  /// Created once per transfer. Stored as a future so frames that arrive
  /// while it's being built all share the same decoder.
  Future<RaptorQDecoder>? _decoder;
  Future<ObjectTransmissionInfo>? _oti;

  /// The transfer this decoder is locked to (set by the first frame).
  StreamKey? _streamKey;

  /// Ids of packets already fed to the decoder. The camera usually reads each
  /// code several times while it's on screen; repeats carry no new data.
  final Set<int> _seenPackets = {};

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

  /// Feeds one frame to the decoder.
  ///
  /// Frames that are unsafe to decode, or that belong to a different transfer
  /// than the first frame, are dropped. Returns whether the frame was used.
  Future<bool> decodeChunk(BlastQrcodeData frame) async {
    if (complete || isLoadingResult) {
      return false;
    }
    if (!frame.isDecodable) {
      debugPrint('Dropping frame with unsafe header');
      return false;
    }

    // Everything up to the first await runs synchronously, so frames from
    // the same camera image can't create two decoders.
    final key = frame.streamKey;
    if (_streamKey == null) {
      _streamKey = key;
      _oti = ObjectTransmissionInfo.withDefaults(
        transferLength: BigInt.from(frame.transferLength),
        // The MTU RaptorQ was given; it rounds this back down to symbolSize.
        maxPacketSize: frame.data.length,
      );
      _decoder = _oti!.then((oti) => RaptorQDecoder.newInstance(oti: oti));
    } else if (key != _streamKey) {
      debugPrint('Dropping frame from another transfer');
      return false;
    }

    // Packet id: source block number (u8) + symbol id (u24). Checked before
    // the first await, so two reads of the same code can't both get through.
    final data = frame.data;
    final packetId =
        (data[0] << 24) | (data[1] << 16) | (data[2] << 8) | data[3];
    if (!_seenPackets.add(packetId)) {
      return false;
    }

    try {
      final oti = await _oti!;
      // Packets for a block that doesn't exist would crash the decoder.
      final sourceBlockNumber = frame.data[0];
      if (sourceBlockNumber >= oti.sourceBlocks) {
        return false;
      }

      final decoder = await _decoder!;
      if (complete) return false;
      final result = await decoder.addPacket(packet: frame.data);

      if (result != null) {
        _handleOutput(result);
        return true;
      }
    } catch (error) {
      // A malformed packet must not take the whole transfer down.
      debugPrint('RaptorQ rejected packet: $error');
      return false;
    }

    // Progress counts unique packets only. ~K of them complete the transfer.
    count += 1;

    final sourceSymbols = (frame.transferLength / frame.symbolSize).ceil();
    estimatedProgress = count / sourceSymbols;
    onProcessChunk?.call(frame.data.length, count, estimatedProgress);
    return true;
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
    _seenPackets.clear();
    _disposeDecoder();
  }

  void dispose() {
    _disposeDecoder();
  }

  void _disposeDecoder() {
    final decoder = _decoder;
    _decoder = null;
    _oti = null;
    _streamKey = null;
    decoder?.then((d) => d.dispose()).catchError((_) {});
  }
}
