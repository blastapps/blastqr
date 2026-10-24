import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:blast_qr/model/blast_qrcode_data.dart';
import 'package:blast_qr/model/transfer_container.dart';

/// Thrown when a transfer decompresses to more than the content limit
/// ([BlastQrcodeData.maxFileBytes] by default).
class ReceivedFileTooLargeException implements Exception {
  @override
  String toString() => 'Received file exceeds the size limit';
}

/// Writes a decoded transfer object (see [TransferContainer]) to
/// [outputPath] in a background isolate and returns its metadata. The content
/// (everything after the metadata) is what ends up in the file.
///
/// When [gzipped], the data is decompressed in chunks straight to disk, so a
/// small stream that inflates to gigabytes ("gzip bomb") stops at the size
/// limit instead of filling memory. On any error the output file is deleted
/// and the error is rethrown.
Future<TransferMetadata> writeReceivedFile({
  required Uint8List data,
  required bool gzipped,
  required String outputPath,
  int maxContentBytes = BlastQrcodeData.maxFileBytes,
}) {
  return Isolate.run(() => _write(data, gzipped, outputPath, maxContentBytes));
}

TransferMetadata _write(
  Uint8List data,
  bool gzipped,
  String outputPath,
  int maxContentBytes,
) {
  final file = File(outputPath);
  final sink = _ContainerSink(
    file.openSync(mode: FileMode.write),
    maxContentBytes: maxContentBytes,
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
    return sink.metadata;
  } catch (_) {
    sink.close();
    if (file.existsSync()) file.deleteSync();
    rethrow;
  }
}

/// Splits the transfer object into its metadata (kept in memory) and content
/// (written to [_file]), failing once the content passes [maxContentBytes].
class _ContainerSink implements Sink<List<int>> {
  _ContainerSink(this._file, {required this.maxContentBytes});

  final RandomAccessFile _file;
  final int maxContentBytes;
  final _header = BytesBuilder();

  /// The 2-byte length prefix first; then the full metadata length is known.
  int _headerLength = 2;
  bool _lengthKnown = false;
  int _contentBytes = 0;
  bool _closed = false;

  TransferMetadata get metadata {
    if (!_lengthKnown || _header.length < _headerLength) {
      throw const FormatException('Transfer is shorter than its metadata');
    }
    return TransferContainer.decodeMetadata(_header.toBytes().sublist(2));
  }

  @override
  void add(List<int> chunk) {
    var offset = 0;
    while (offset < chunk.length && _header.length < _headerLength) {
      final take = math.min(_headerLength - _header.length, chunk.length - offset);
      _header.add(chunk.sublist(offset, offset + take));
      offset += take;
      _readMetadataLength();
    }
    if (offset >= chunk.length) return;

    _contentBytes += chunk.length - offset;
    if (_contentBytes > maxContentBytes) {
      throw ReceivedFileTooLargeException();
    }
    _file.writeFromSync(chunk, offset);
  }

  /// Once the 2-byte prefix is in, the full metadata length is known.
  void _readMetadataLength() {
    if (_lengthKnown || _header.length < 2) return;
    final prefix = _header.toBytes();
    _headerLength = 2 + ((prefix[0] << 8) | prefix[1]);
    _lengthKnown = true;
  }

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    _file.closeSync();
  }
}
