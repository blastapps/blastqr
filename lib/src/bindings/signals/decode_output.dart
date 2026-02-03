// ignore_for_file: type=lint, type=warning
part of 'signals.dart';


@immutable
class DecodeOutput {
  /// An async broadcast stream that listens for signals from Rust.
  /// It supports multiple subscriptions.
  /// Make sure to cancel the subscription when it's no longer needed,
  /// such as when a widget is disposed.
  static final rustSignalStream =
      _decodeOutputStreamController.stream.asBroadcastStream();
        
  /// The latest signal value received from Rust.
  /// This is updated every time a new signal is received.
  /// It can be null if no signals have been received yet.
  static RustSignalPack<DecodeOutput>? latestRustSignal = null;

  const DecodeOutput({
    required this.result,
    required this.time,
    required this.chunkLen,
  });

  static DecodeOutput deserialize(BinaryDeserializer deserializer) {
    deserializer.increaseContainerDepth();
    final instance = DecodeOutput(
      result: TraitHelpers.deserializeVectorU8(deserializer),
      time: deserializer.deserializeInt32(),
      chunkLen: deserializer.deserializeInt32(),
    );
    deserializer.decreaseContainerDepth();
    return instance;
  }

  static DecodeOutput bincodeDeserialize(Uint8List input) {
    final deserializer = BincodeDeserializer(input);
    final value = DecodeOutput.deserialize(deserializer);
    if (deserializer.offset < input.length) {
      throw Exception('Some input bytes were not read');
    }
    return value;
  }

  final List<int> result;
  final int time;
  final int chunkLen;

  DecodeOutput copyWith({
    List<int>? result,
    int? time,
    int? chunkLen,
  }) {
    return DecodeOutput(
      result: result ?? this.result,
      time: time ?? this.time,
      chunkLen: chunkLen ?? this.chunkLen,
    );
  }

  void serialize(BinarySerializer serializer) {
    serializer.increaseContainerDepth();
    TraitHelpers.serializeVectorU8(result, serializer);
    serializer.serializeInt32(time);
    serializer.serializeInt32(chunkLen);
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

    return other is DecodeOutput
      && listEquals(result, other.result)
      && time == other.time
      && chunkLen == other.chunkLen;
  }

  @override
  int get hashCode => Object.hash(
        result,
        time,
        chunkLen,
      );

  @override
  String toString() {
    String? fullString;

    assert(() {
      fullString = '$runtimeType('
        'result: $result, '
        'time: $time, '
        'chunkLen: $chunkLen'
        ')';
      return true;
    }());

    return fullString ?? 'DecodeOutput';
  }
}

final _decodeOutputStreamController =
    StreamController<RustSignalPack<DecodeOutput>>();
