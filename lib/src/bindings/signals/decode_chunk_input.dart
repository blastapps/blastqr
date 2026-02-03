// ignore_for_file: type=lint, type=warning
part of 'signals.dart';


@immutable
class DecodeChunkInput {
  const DecodeChunkInput({
    required this.data,
    required this.mtu,
    required this.transferLength,
    required this.reset,
  });

  static DecodeChunkInput deserialize(BinaryDeserializer deserializer) {
    deserializer.increaseContainerDepth();
    final instance = DecodeChunkInput(
      data: TraitHelpers.deserializeVectorU8(deserializer),
      mtu: deserializer.deserializeInt32(),
      transferLength: deserializer.deserializeInt32(),
      reset: deserializer.deserializeBool(),
    );
    deserializer.decreaseContainerDepth();
    return instance;
  }

  static DecodeChunkInput bincodeDeserialize(Uint8List input) {
    final deserializer = BincodeDeserializer(input);
    final value = DecodeChunkInput.deserialize(deserializer);
    if (deserializer.offset < input.length) {
      throw Exception('Some input bytes were not read');
    }
    return value;
  }

  final List<int> data;
  final int mtu;
  final int transferLength;
  final bool reset;

  DecodeChunkInput copyWith({
    List<int>? data,
    int? mtu,
    int? transferLength,
    bool? reset,
  }) {
    return DecodeChunkInput(
      data: data ?? this.data,
      mtu: mtu ?? this.mtu,
      transferLength: transferLength ?? this.transferLength,
      reset: reset ?? this.reset,
    );
  }

  void serialize(BinarySerializer serializer) {
    serializer.increaseContainerDepth();
    TraitHelpers.serializeVectorU8(data, serializer);
    serializer.serializeInt32(mtu);
    serializer.serializeInt32(transferLength);
    serializer.serializeBool(reset);
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

    return other is DecodeChunkInput
      && listEquals(data, other.data)
      && mtu == other.mtu
      && transferLength == other.transferLength
      && reset == other.reset;
  }

  @override
  int get hashCode => Object.hash(
        data,
        mtu,
        transferLength,
        reset,
      );

  @override
  String toString() {
    String? fullString;

    assert(() {
      fullString = '$runtimeType('
        'data: $data, '
        'mtu: $mtu, '
        'transferLength: $transferLength, '
        'reset: $reset'
        ')';
      return true;
    }());

    return fullString ?? 'DecodeChunkInput';
  }
}

extension DecodeChunkInputDartSignalExt on DecodeChunkInput {
  /// Sends the signal to Rust.
  /// Passing data from Rust to Dart involves a memory copy
  /// because Rust cannot own data managed by Dart's garbage collector.
  void sendSignalToRust() {
    final messageBytes = bincodeSerialize();
    final binary = Uint8List(0);
    sendDartSignal(
      'rinf_send_dart_signal_decode_chunk_input',
      messageBytes,
      binary,
    );
  }
}
