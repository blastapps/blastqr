// ignore_for_file: type=lint, type=warning
part of 'signals.dart';


@immutable
class StreamEncodeInput {
  const StreamEncodeInput(
  );

  static StreamEncodeInput deserialize(BinaryDeserializer deserializer) {
    deserializer.increaseContainerDepth();
    final instance = StreamEncodeInput(
    );
    deserializer.decreaseContainerDepth();
    return instance;
  }

  static StreamEncodeInput bincodeDeserialize(Uint8List input) {
    final deserializer = BincodeDeserializer(input);
    final value = StreamEncodeInput.deserialize(deserializer);
    if (deserializer.offset < input.length) {
      throw Exception('Some input bytes were not read');
    }
    return value;
  }

  void serialize(BinarySerializer serializer) {
    serializer.increaseContainerDepth();
    serializer.decreaseContainerDepth();
  }

  Uint8List bincodeSerialize() {
      final serializer = BincodeSerializer();
      serialize(serializer);
      return serializer.bytes;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;

    return other is StreamEncodeInput;
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    String? fullString;

    assert(() {
      fullString = '$runtimeType('
        ')';
      return true;
    }());

    return fullString ?? 'StreamEncodeInput';
  }
}

extension StreamEncodeInputDartSignalExt on StreamEncodeInput {
  /// Sends the signal to Rust with separate binary data.
  /// Passing data from Rust to Dart involves a memory copy
  /// because Rust cannot own data managed by Dart's garbage collector.
  void sendSignalToRust(Uint8List binary) {
    final messageBytes = bincodeSerialize();
    sendDartSignal(
      'rinf_send_dart_signal_stream_encode_input',
      messageBytes,
      binary,
    );
  }
}
