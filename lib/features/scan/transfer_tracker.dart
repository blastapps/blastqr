import 'dart:typed_data';

import 'package:blast_qr/model/blast_qrcode_data.dart';

/// What the receiver should do with a scanned QR code.
enum ScanAction {
  /// Not a BlastQR frame: handle it as an ordinary QR code.
  foreign,

  /// A stream this app can't read (newer version, or a must-understand
  /// feature such as encryption): ask the user to update.
  updateRequired,

  /// Nothing to do (misread, unsafe header, or another transfer that isn't
  /// taking over).
  ignore,

  /// First frame of a new transfer: set it up, then decode the frame.
  start,

  /// The previous transfer went quiet and a new one is arriving: drop the
  /// old progress, set up the new transfer, then decode the frame.
  switchTransfer,

  /// Another frame of the current transfer: decode it.
  decode,
}

/// Decides, frame by frame, which transfer the receiver follows.
///
/// The first valid frame locks onto its transfer (its [StreamKey]). Frames
/// from another transfer are ignored while the current one is still arriving
/// (e.g. a second sender in view). Once the current one has been quiet for
/// [switchAfter] (e.g. the sender picked another file), the next new
/// transfer takes over.
class TransferTracker {
  TransferTracker({this.switchAfter = const Duration(milliseconds: 1500)});

  final Duration switchAfter;

  StreamKey? _current;
  DateTime? _lastFrameAt;

  /// The transfer being received, if any.
  StreamKey? get current => _current;

  /// Classifies one scanned code. [busy] blocks switching (e.g. while the
  /// current transfer's file is being saved). For [ScanAction.start],
  /// [ScanAction.switchTransfer] and [ScanAction.decode] the parsed frame is
  /// returned too.
  ({ScanAction action, BlastQrcodeData? frame}) handle(
    Uint8List? bytes,
    DateTime now, {
    bool busy = false,
  }) {
    final parsed = BlastQrcodeData.parse(bytes);
    switch (parsed.verdict) {
      case FrameVerdict.foreign:
        return (action: ScanAction.foreign, frame: null);
      case FrameVerdict.newerVersion:
      case FrameVerdict.unsupportedFlags:
        return (action: ScanAction.updateRequired, frame: null);
      case FrameVerdict.malformed:
        return (action: ScanAction.ignore, frame: null);
      case FrameVerdict.ok:
        break;
    }

    final frame = parsed.frame!;
    // Unsafe headers are ignored, like a missed frame.
    if (!frame.isDecodable) {
      return (action: ScanAction.ignore, frame: null);
    }

    final key = frame.streamKey;
    if (_current == null) {
      _current = key;
      _lastFrameAt = now;
      return (action: ScanAction.start, frame: frame);
    }
    if (key == _current) {
      _lastFrameAt = now;
      return (action: ScanAction.decode, frame: frame);
    }
    if (busy || now.difference(_lastFrameAt!) < switchAfter) {
      return (action: ScanAction.ignore, frame: null);
    }
    _current = key;
    _lastFrameAt = now;
    return (action: ScanAction.switchTransfer, frame: frame);
  }

  /// Forgets the current transfer.
  void reset() {
    _current = null;
    _lastFrameAt = null;
  }
}
