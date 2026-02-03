// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:typed_data';

import 'package:blast_qr/src/bindings/signals/signals.dart';

class RaptorqStreamingEncoder {
  final int repairPacketsPerBlock;
  final int mtu;

  RaptorqStreamingEncoder({this.repairPacketsPerBlock = 15, this.mtu = 700});

  void initialize() {
    StreamEncodeConfig(
      mtu: mtu,
      repairPacketsPerBlock: repairPacketsPerBlock,
    ).sendSignalToRust();
  }

  Stream<Uint8List> encode(Uint8List data) {
    StreamController<Uint8List> ctrl = StreamController();

    final chunkSub = StreamEncodeOutput.rustSignalStream.listen((data) {
      ctrl.add(data.binary);
    });

    final completionSub = StreamEncodeComplete.rustSignalStream.listen((_) {
      ctrl.close();
    });

    const StreamEncodeInput().sendSignalToRust(data);

    ctrl.onCancel = () {
      chunkSub.cancel();
      completionSub.cancel();
    };

    return ctrl.stream;
  }
}
