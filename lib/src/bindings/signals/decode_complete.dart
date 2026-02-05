// ignore_for_file: type=lint, type=warning
part of 'signals.dart';


@immutable
class DecodeComplete {
  /// An async broadcast stream that listens for signals from Rust.
  /// It supports multiple subscriptions.
  /// Make sure to cancel the subscription when it's no longer needed,
  /// such as when a widget is disposed.
  static final rustSignalStream =
      _decodeCompleteStreamController.stream.asBroadcastStream();
        
  /// The latest signal value received from Rust.
  /// This is updated every time a new signal is received.
  /// It can be null if no signals have been received yet.
  static RustSignalPack<DecodeComplete>? latestRustSignal = null;

  const DecodeComplete({
    required this.time,
  });

  static DecodeComplete deserialize(BinaryDeserializer deserializer) {
    deserializer.increaseContainerDepth();
    final instance = DecodeComplete(
      time: deserializer.deserializeInt32(),
    );
    deserializer.decreaseContainerDepth();
    return instance;
  }

  static DecodeComplete bincodeDeserialize(Uint8List input) {
    final deserializer = BincodeDeserializer(input);
    final value = DecodeComplete.deserialize(deserializer);
    if (deserializer.offset < input.length) {
      throw Exception('Some input bytes were not read');
    }
    return value;
  }

  final int time;

  DecodeComplete copyWith({
    int? time,
  }) {
    return DecodeComplete(
      time: time ?? this.time,
    );
  }

  void serialize(BinarySerializer serializer) {
    serializer.increaseContainerDepth();
    serializer.serializeInt32(time);
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

    return other is DecodeComplete
      && time == other.time;
  }

  @override
  int get hashCode => time.hashCode;

  @override
  String toString() {
    String? fullString;

    assert(() {
      fullString = '$runtimeType('
        'time: $time'
        ')';
      return true;
    }());

    return fullString ?? 'DecodeComplete';
  }
}

final _decodeCompleteStreamController =
    StreamController<RustSignalPack<DecodeComplete>>();
