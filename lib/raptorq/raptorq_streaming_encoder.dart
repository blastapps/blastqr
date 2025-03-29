// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:typed_data';

import 'package:blast_qr/messages/basic.pb.dart';

class RaptorqStreamingEncoder {
  final int repairPacketsPerBlock;
  final int mtu;

  RaptorqStreamingEncoder({this.repairPacketsPerBlock = 15, this.mtu = 700});

  Stream<RaptorqTransfer> encode(Uint8List data) {
    StreamEncodeInput(
      data: data,
      mtu: mtu,
      repairPacketsPerBlock: repairPacketsPerBlock,
    ).sendSignalToRust();

    return StreamEncodeOutput.rustSignalStream.map(
      (data) => RaptorqTransfer(
        data: data.message.result as Uint8List,
        isComplete: data.message.isComplete,
      ),
    );
  }
}

class RaptorqTransfer {
  final bool isComplete;
  final Uint8List data;
  RaptorqTransfer({required this.isComplete, required this.data});
}
