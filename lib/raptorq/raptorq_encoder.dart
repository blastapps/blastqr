import 'dart:typed_data';

import 'package:blast_qr/messages/basic.pb.dart';

class RaptorqEncoder {
  final int repairPacketsPerBlock;
  final int mtu;

  RaptorqEncoder({this.repairPacketsPerBlock = 15, this.mtu = 700});

  Future<List<Uint8List>> encode(Uint8List data) async {
    EncodeInput(
      data: data,
      mtu: mtu,
      repairPacketsPerBlock: repairPacketsPerBlock,
    ).sendSignalToRust();

    final signal = await EncodeOutput.rustSignalStream.first;
    final List<Uint8List> result = [];
    for (final block in signal.message.result) {
      result.add(Uint8List.fromList(block));
    }

    return result;
  }
}
