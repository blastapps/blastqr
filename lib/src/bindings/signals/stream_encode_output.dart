// ignore_for_file: type=lint, type=warning
part of 'signals.dart';


@immutable
class StreamEncodeOutput {
  /// An async broadcast stream that listens for signals from Rust.
  /// It supports multiple subscriptions.
  /// Make sure to cancel the subscription when it's no longer needed,
  /// such as when a widget is disposed.
  static final rustSignalStream =
      _streamEncodeOutputStreamController.stream.asBroadcastStream();
        
  /// The latest signal value received from Rust.
  /// This is updated every time a new signal is received.
  /// It can be null if no signals have been received yet.
  static RustSignalPack<StreamEncodeOutput>? latestRustSignal = null;

  const StreamEncodeOutput(
  );

  static StreamEncodeOutput deserialize(BinaryDeserializer deserializer) {
    deserializer.increaseContainerDepth();
    final instance = StreamEncodeOutput(
    );
    deserializer.decreaseContainerDepth();
    return instance;
  }

  static StreamEncodeOutput bincodeDeserialize(Uint8List input) {
    final deserializer = BincodeDeserializer(input);
    final value = StreamEncodeOutput.deserialize(deserializer);
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

    return other is StreamEncodeOutput;
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

    return fullString ?? 'StreamEncodeOutput';
  }
}

final _streamEncodeOutputStreamController =
    StreamController<RustSignalPack<StreamEncodeOutput>>();
