import 'package:flutter/foundation.dart';

/// What a scanned QR code turned out to be.
enum FrameVerdict {
  /// A BlastQR frame this app can decode.
  ok,

  /// Not a BlastQR frame (any other QR code).
  foreign,

  /// A BlastQR frame from a newer protocol version.
  newerVersion,

  /// A BlastQR frame using a feature this app doesn't support (an unknown
  /// must-understand flag).
  unsupportedFlags,

  /// Looks like ours but isn't self-consistent. Treated like a misread frame.
  malformed,
}

/// Values that stay the same for every frame of one transfer.
typedef StreamKey =
    ({int sessionId, int transferLength, int symbolSize, int flags, int kind});

/// One BlastQR frame: a header plus one RaptorQ packet.
///
/// Version 2, 14-byte header:
/// ```
/// 0  3  signature       "bQR"
/// 3  1  version         2
/// 4  1  flags           see flag* constants
/// 5  1  kind            see kind* constants
/// 6  2  sessionId       u16 BE, random per send
/// 8  4  transferLength  u32 BE, size of the transfer object
/// 12 2  symbolSize      u16 BE, RaptorQ symbol size T
/// 14    RaptorQ packet  4-byte packet id + T bytes
/// ```
class BlastQrcodeData {
  /// "bQR". Future versions keep this signature and change the version
  /// byte, so receivers can say "update the app".
  static final signatureBytes = Uint8List.fromList([0x62, 0x51, 0x52]);

  static const int protocolVersion = 2;
  static const int headerLength = 14;

  /// Flags. The low 4 bits must be understood: a frame with an unknown bit
  /// there is rejected with "update the app". The high 4 bits are optional
  /// hints that older apps may ignore.
  static const int flagGzip = 0x01;

  /// The transfer object is an encrypted envelope (see TransferCrypto).
  static const int flagEncrypted = 0x02;
  static const int mustUnderstandFlags = 0x0F;

  /// Must-understand flags this app supports.
  static const int supportedFlags = flagGzip | flagEncrypted;

  /// What is being sent. Unknown kinds are received as plain files, so new
  /// kinds never break older apps.
  static const int kindFile = 0;

  /// RaptorQ packet id (source block number + symbol id) before each symbol.
  static const int packetIdLength = 4;

  /// Room reserved for the v2 metadata block (see TransferContainer).
  static const int maxMetadataBytes = 1024;

  /// Largest file content we send or accept (~4 GB). Together with the
  /// metadata it still fits the u32 `transferLength` header field.
  static const int maxFileBytes = 0xFFFFFFFF - maxMetadataBytes;

  /// Smallest symbol size we accept. Senders start at MTU 100, and below 64
  /// RaptorQ switches alignment, which breaks building the decoder.
  static const int minSymbolSize = 64;

  /// Most symbols a transfer may have. The RaptorQ decoder reserves memory
  /// per symbol as soon as it's created, so this caps what one frame can make
  /// us allocate. Still allows ~4.3 GB at the default MTU.
  static const int maxSymbolCount = 1500000;

  /// Symbol size RaptorQ uses for a given MTU (rounded down to 8).
  static int symbolSizeForMtu(int mtu) => mtu - mtu % 8;

  /// Whether a transfer of [transferLength] bytes stays within
  /// [maxSymbolCount] at [symbolSize].
  static bool fitsSymbolLimit(int transferLength, int symbolSize) =>
      (transferLength / symbolSize).ceil() <= maxSymbolCount;

  final int flags;
  final int kind;
  final int sessionId;
  final int transferLength;
  final int symbolSize;

  /// The RaptorQ packet (packet id + symbol).
  final Uint8List data;

  BlastQrcodeData({
    required this.flags,
    required this.kind,
    required this.sessionId,
    required this.transferLength,
    required this.symbolSize,
    required this.data,
  });

  bool get isCompressedData => flags & flagGzip != 0;

  bool get isEncrypted => flags & flagEncrypted != 0;

  /// Builds the 14-byte v2 header. Every frame of a transfer shares it.
  static Uint8List buildHeader({
    required int flags,
    required int kind,
    required int sessionId,
    required int transferLength,
    required int symbolSize,
  }) {
    final header = Uint8List(headerLength);
    header.setAll(0, signatureBytes);
    header[3] = protocolVersion;
    header[4] = flags;
    header[5] = kind;
    header.buffer.asByteData()
      ..setUint16(6, sessionId, Endian.big)
      ..setUint32(8, transferLength, Endian.big)
      ..setUint16(12, symbolSize, Endian.big);
    return header;
  }

  /// Parses a scanned QR code. [FrameVerdict.ok] comes with a frame.
  static ({FrameVerdict verdict, BlastQrcodeData? frame}) parse(
    Uint8List? bytes,
  ) {
    if (bytes == null || bytes.length < 4) {
      return (verdict: FrameVerdict.foreign, frame: null);
    }
    if (bytes[0] != signatureBytes[0] ||
        bytes[1] != signatureBytes[1] ||
        bytes[2] != signatureBytes[2]) {
      return (verdict: FrameVerdict.foreign, frame: null);
    }

    final version = bytes[3];
    if (version < protocolVersion) {
      return (verdict: FrameVerdict.malformed, frame: null);
    }
    if (version > protocolVersion) {
      return (verdict: FrameVerdict.newerVersion, frame: null);
    }
    if (bytes.length < headerLength + packetIdLength) {
      return (verdict: FrameVerdict.malformed, frame: null);
    }

    final flags = bytes[4];
    if (flags & mustUnderstandFlags & ~supportedFlags != 0) {
      return (verdict: FrameVerdict.unsupportedFlags, frame: null);
    }

    final view = ByteData.sublistView(bytes);
    final symbolSize = view.getUint16(12, Endian.big);
    final data = Uint8List.fromList(bytes.sublist(headerLength));
    // The frame must be exactly one header + one packet.
    if (data.length != packetIdLength + symbolSize) {
      return (verdict: FrameVerdict.malformed, frame: null);
    }

    return (
      verdict: FrameVerdict.ok,
      frame: BlastQrcodeData(
        flags: flags,
        kind: bytes[5],
        sessionId: view.getUint16(6, Endian.big),
        transferLength: view.getUint32(8, Endian.big),
        symbolSize: symbolSize,
        data: data,
      ),
    );
  }

  /// Whether the header describes a transfer we can safely build a decoder
  /// for. Every frame from a real sender passes; this only rejects values
  /// that would make the RaptorQ decoder over-allocate or crash.
  bool get isDecodable =>
      symbolSize >= minSymbolSize &&
      symbolSize % 8 == 0 &&
      // At least the 2-byte metadata length of the container.
      transferLength >= 2 &&
      fitsSymbolLimit(transferLength, symbolSize);

  /// Frames with a different key belong to another transfer.
  StreamKey get streamKey => (
    sessionId: sessionId,
    transferLength: transferLength,
    symbolSize: symbolSize,
    flags: flags,
    kind: kind,
  );
}
