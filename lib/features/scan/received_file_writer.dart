import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:blast_qr/model/blast_qrcode_data.dart';

/// Thrown when a transfer decompresses to more than the content limit
/// ([BlastQrcodeData.maxFileBytes] by default).
class ReceivedFileTooLargeException implements Exception {
  @override
  String toString() => 'Received file exceeds the size limit';
}

/// Writes a decoded transfer object to [outputPath] in a background isolate
/// and returns its 128-byte filename block.
///
/// When [gzipped], the data is decompressed in chunks straight to disk, so a
/// small stream that inflates to gigabytes ("gzip bomb") stops at the size
/// limit instead of filling memory. On any error the output file is deleted
/// and the error is rethrown.
Future<Uint8List> writeReceivedFile({
  required Uint8List data,
  required bool gzipped,
  required String outputPath,
  int maxContentBytes = BlastQrcodeData.maxFileBytes,
}) {
  return Isolate.run(
    () => _write(data, gzipped, outputPath, maxContentBytes),
  );
}

Uint8List _write(
  Uint8List data,
  bool gzipped,
  String outputPath,
  int maxContentBytes,
) {
  final file = File(outputPath);
  final sink = _NameSplittingSink(
    file.openSync(mode: FileMode.write),
    maxBytes: maxContentBytes + BlastQrcodeData.nameBlockLength,
  );
  try {
    if (gzipped) {
      gzip.decoder.startChunkedConversion(sink)
        ..add(data)
        ..close();
    } else {
      sink
        ..add(data)
        ..close();
    }
    if (sink.nameBlock.length < BlastQrcodeData.nameBlockLength) {
      throw const FormatException('Transfer is shorter than its name block');
    }
    return sink.nameBlock;
  } catch (_) {
    sink.close();
    if (file.existsSync()) file.deleteSync();
    rethrow;
  }
}

/// Collects the leading name block in memory and writes everything after it
/// to [_file], failing once more than [maxBytes] have arrived in total.
class _NameSplittingSink implements Sink<List<int>> {
  _NameSplittingSink(this._file, {required this.maxBytes});

  final RandomAccessFile _file;
  final int maxBytes;
  final _name = BytesBuilder();
  int _total = 0;
  bool _closed = false;

  Uint8List get nameBlock => _name.toBytes();

  @override
  void add(List<int> chunk) {
    _total += chunk.length;
    if (_total > maxBytes) throw ReceivedFileTooLargeException();

    var offset = 0;
    final missing = BlastQrcodeData.nameBlockLength - _name.length;
    if (missing > 0) {
      offset = math.min(missing, chunk.length);
      _name.add(chunk.sublist(0, offset));
    }
    if (offset < chunk.length) _file.writeFromSync(chunk, offset);
  }

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    _file.closeSync();
  }
}
