part of 'signals.dart';

final assignRustSignal = <String, void Function(Uint8List, Uint8List)>{
  'DecodeComplete': (Uint8List messageBytes, Uint8List binary) {
    final message = DecodeComplete.bincodeDeserialize(messageBytes);
    final rustSignal = RustSignalPack(
      message,
      binary,
    );
    _decodeCompleteStreamController.add(rustSignal);
    DecodeComplete.latestRustSignal = rustSignal;
  },
  'DecodeError': (Uint8List messageBytes, Uint8List binary) {
    final message = DecodeError.bincodeDeserialize(messageBytes);
    final rustSignal = RustSignalPack(
      message,
      binary,
    );
    _decodeErrorStreamController.add(rustSignal);
    DecodeError.latestRustSignal = rustSignal;
  },
  'DecodeOutput': (Uint8List messageBytes, Uint8List binary) {
    final message = DecodeOutput.bincodeDeserialize(messageBytes);
    final rustSignal = RustSignalPack(
      message,
      binary,
    );
    _decodeOutputStreamController.add(rustSignal);
    DecodeOutput.latestRustSignal = rustSignal;
  },
  'DecodeProgress': (Uint8List messageBytes, Uint8List binary) {
    final message = DecodeProgress.bincodeDeserialize(messageBytes);
    final rustSignal = RustSignalPack(
      message,
      binary,
    );
    _decodeProgressStreamController.add(rustSignal);
    DecodeProgress.latestRustSignal = rustSignal;
  },
  'StreamEncodeComplete': (Uint8List messageBytes, Uint8List binary) {
    final message = StreamEncodeComplete.bincodeDeserialize(messageBytes);
    final rustSignal = RustSignalPack(
      message,
      binary,
    );
    _streamEncodeCompleteStreamController.add(rustSignal);
    StreamEncodeComplete.latestRustSignal = rustSignal;
  },
  'StreamEncodeOutput': (Uint8List messageBytes, Uint8List binary) {
    final message = StreamEncodeOutput.bincodeDeserialize(messageBytes);
    final rustSignal = RustSignalPack(
      message,
      binary,
    );
    _streamEncodeOutputStreamController.add(rustSignal);
    StreamEncodeOutput.latestRustSignal = rustSignal;
  },
};
