import 'dart:convert';
import 'dart:typed_data';

extension StringExtension on String {
  /// Encodes string in to 128 bytes fixed lenght Uint8list
  Uint8List encodeFixed128() {
    List<int> bytes = utf8.encode(this);

    int cutoff = bytes.length > 128 ? 128 : bytes.length;

    // Ensure we don't cut a multi-byte character
    while (cutoff > 0 &&
        cutoff < bytes.length &&
        (bytes[cutoff] & 0xC0) == 0x80) {
      cutoff--; // Move back until we find a valid character start
    }

    Uint8List result = Uint8List(128);
    result.setRange(0, cutoff, bytes.sublist(0, cutoff));

    return result;
  }
}
