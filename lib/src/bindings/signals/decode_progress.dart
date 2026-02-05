// ignore_for_file: type=lint, type=warning
part of 'signals.dart';


@immutable
class DecodeProgress {
  /// An async broadcast stream that listens for signals from Rust.
  /// It supports multiple subscriptions.
  /// Make sure to cancel the subscription when it's no longer needed,
  /// such as when a widget is disposed.
  static final rustSignalStream =
      _decodeProgressStreamController.stream.asBroadcastStream();
        
  /// The latest signal value received from Rust.
  /// This is updated every time a new signal is received.
  /// It can be null if no signals have been received yet.
  static RustSignalPack<DecodeProgress>? latestRustSignal = null;

  const DecodeProgress({
    required this.chunkLen,
  });

  static DecodeProgress deserialize(BinaryDeserializer deserializer) {
    deserializer.increaseContainerDepth();
    final instance = DecodeProgress(
      chunkLen: deserializer.deserializeInt32(),
    );
    deserializer.decreaseContainerDepth();
    return instance;
  }

  static DecodeProgress bincodeDeserialize(Uint8List input) {
    final deserializer = BincodeDeserializer(input);
    final value = DecodeProgress.deserialize(deserializer);
    if (deserializer.offset < input.length) {
      throw Exception('Some input bytes were not read');
    }
    return value;
  }

  final int chunkLen;

  DecodeProgress copyWith({
    int? chunkLen,
  }) {
    return DecodeProgress(
      chunkLen: chunkLen ?? this.chunkLen,
    );
  }

  void serialize(BinarySerializer serializer) {
    serializer.increaseContainerDepth();
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

    return other is DecodeProgress
      && chunkLen == other.chunkLen;
  }

  @override
  int get hashCode => chunkLen.hashCode;

  @override
  String toString() {
    String? fullString;

    assert(() {
      fullString = '$runtimeType('
        'chunkLen: $chunkLen'
        ')';
      return true;
    }());

    return fullString ?? 'DecodeProgress';
  }
}

final _decodeProgressStreamController =
    StreamController<RustSignalPack<DecodeProgress>>();
