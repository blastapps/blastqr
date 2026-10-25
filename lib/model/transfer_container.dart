import 'dart:convert';
import 'dart:typed_data';

import 'package:blast_qr/model/blast_qrcode_data.dart';

/// Metadata carried inside a v2 transfer.
class TransferMetadata {
  final String? fileName;

  /// The content is a zip of several files, to be extracted by the receiver.
  final bool isBundle;

  const TransferMetadata({this.fileName, this.isBundle = false});
}

/// The v2 transfer object, before compression:
///
/// ```
/// u16 BE  metadata length (M)
/// M bytes metadata entries, each: u8 tag · u16 BE length · value
/// …       file content
/// ```
///
/// Unknown tags are skipped, so new metadata (e.g. a MIME type) can be added
/// without a new protocol version. Everything here, filename included, is
/// inside the payload, so a future encryption layer covers it.
class TransferContainer {
  const TransferContainer._();

  static const int tagFileName = 1;
  static const int tagBundle = 2;

  /// Longest filename sent, in UTF-8 bytes.
  static const int maxFileNameBytes = 255;

  /// Builds the metadata block, including its 2-byte length prefix.
  static Uint8List encodeMetadata({
    required String fileName,
    bool isBundle = false,
  }) {
    final name = _truncateUtf8(utf8.encode(fileName), maxFileNameBytes);
    final entries = BytesBuilder()
      ..addByte(tagFileName)
      ..add(_u16(name.length))
      ..add(name);
    if (isBundle) {
      entries
        ..addByte(tagBundle)
        ..add(_u16(0));
    }
    final body = entries.toBytes();
    assert(body.length + 2 <= BlastQrcodeData.maxMetadataBytes);
    return (BytesBuilder()
          ..add(_u16(body.length))
          ..add(body))
        .toBytes();
  }

  /// Parses metadata entries (the block without its length prefix).
  /// Throws [FormatException] if an entry runs past the end.
  static TransferMetadata decodeMetadata(Uint8List block) {
    final view = ByteData.sublistView(block);
    String? fileName;
    var isBundle = false;
    var offset = 0;
    while (offset < block.length) {
      if (offset + 3 > block.length) {
        throw const FormatException('Truncated metadata entry');
      }
      final tag = block[offset];
      final length = view.getUint16(offset + 1, Endian.big);
      final start = offset + 3;
      final end = start + length;
      if (end > block.length) {
        throw const FormatException('Metadata entry runs past the end');
      }
      if (tag == tagFileName) {
        fileName = utf8.decode(block.sublist(start, end), allowMalformed: true);
      } else if (tag == tagBundle) {
        isBundle = true;
      }
      offset = end;
    }
    return TransferMetadata(fileName: fileName, isBundle: isBundle);
  }

  static Uint8List _u16(int value) =>
      Uint8List(2)..buffer.asByteData().setUint16(0, value, Endian.big);

  /// Cuts [bytes] to at most [max] without splitting a UTF-8 character.
  static List<int> _truncateUtf8(List<int> bytes, int max) {
    if (bytes.length <= max) return bytes;
    var cut = max;
    while (cut > 0 && (bytes[cut] & 0xC0) == 0x80) {
      cut--;
    }
    return bytes.sublist(0, cut);
  }
}
