// ignore_for_file: type=lint, type=warning
part of 'signals.dart';


@immutable
class StreamEncodeConfig {
  const StreamEncodeConfig({
    required this.mtu,
    required this.repairPacketsPerBlock,
  });

  static StreamEncodeConfig deserialize(BinaryDeserializer deserializer) {
    deserializer.increaseContainerDepth();
    final instance = StreamEncodeConfig(
      mtu: deserializer.deserializeInt32(),
      repairPacketsPerBlock: deserializer.deserializeUint32(),
    );
    deserializer.decreaseContainerDepth();
    return instance;
  }

  static StreamEncodeConfig bincodeDeserialize(Uint8List input) {
    final deserializer = BincodeDeserializer(input);
    final value = StreamEncodeConfig.deserialize(deserializer);
    if (deserializer.offset < input.length) {
      throw Exception('Some input bytes were not read');
    }
    return value;
  }

  final int mtu;
  final int repairPacketsPerBlock;

  StreamEncodeConfig copyWith({
    int? mtu,
    int? repairPacketsPerBlock,
  }) {
    return StreamEncodeConfig(
      mtu: mtu ?? this.mtu,
      repairPacketsPerBlock: repairPacketsPerBlock ?? this.repairPacketsPerBlock,
    );
  }

  void serialize(BinarySerializer serializer) {
    serializer.increaseContainerDepth();
    serializer.serializeInt32(mtu);
    serializer.serializeUint32(repairPacketsPerBlock);
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

    return other is StreamEncodeConfig
      && mtu == other.mtu
      && repairPacketsPerBlock == other.repairPacketsPerBlock;
  }

  @override
  int get hashCode => Object.hash(
        mtu,
        repairPacketsPerBlock,
      );

  @override
  String toString() {
    String? fullString;

    assert(() {
      fullString = '$runtimeType('
        'mtu: $mtu, '
        'repairPacketsPerBlock: $repairPacketsPerBlock'
        ')';
      return true;
    }());

    return fullString ?? 'StreamEncodeConfig';
  }
}

extension StreamEncodeConfigDartSignalExt on StreamEncodeConfig {
  /// Sends the signal to Rust.
  /// Passing data from Rust to Dart involves a memory copy
  /// because Rust cannot own data managed by Dart's garbage collector.
  void sendSignalToRust() {
    final messageBytes = bincodeSerialize();
    final binary = Uint8List(0);
    sendDartSignal(
      'rinf_send_dart_signal_stream_encode_config',
      messageBytes,
      binary,
    );
  }
}
