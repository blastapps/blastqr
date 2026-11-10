import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:blast_qr/file_name_utils.dart';

/// One file to put in a bundle: its name and either a path or its bytes.
typedef BundleEntry = ({String name, String? path, Uint8List? bytes});

/// Writes [entries] to a zip at [outputPath], without compression (gzip is
/// applied to the whole transfer later). Names are cleaned and made unique.
Future<void> writeBundle(List<BundleEntry> entries, String outputPath) {
  return Isolate.run(() {
    final output = OutputFileStream(outputPath);
    try {
      final encoder = ZipEncoder()..startEncode(output);
      final names = <String>{};
      for (final entry in entries) {
        final name = uniqueFileName(
          sanitizeFileName(entry.name),
          names.contains,
        );
        names.add(name);
        final bytes = entry.bytes ?? File(entry.path!).readAsBytesSync();
        encoder.add(
          ArchiveFile.bytes(name, bytes)..compression = CompressionType.none,
        );
      }
      encoder.endEncode();
    } finally {
      output.closeSync();
    }
  });
}

/// Thrown when a bundle can't be extracted, e.g. it isn't a zip or has
/// compressed entries.
class BundleFormatException implements Exception {
  const BundleFormatException(this.message);

  final String message;

  @override
  String toString() => 'BundleFormatException: $message';
}

/// Extracts the zip at [zipPath] into [directory] and returns the paths of
/// the new files. Entry names are untrusted: only the cleaned last path
/// segment is used, made unique in [directory].
///
/// Bundles are zipped without compression (the whole transfer is gzipped
/// separately), so a real bundle extracts to slightly less than the zip's
/// size. Compressed entries are refused, and so is output larger than the
/// zip: that only happens when a crafted zip has entries sharing data, which
/// could otherwise fill the disk. On any error, files written so far are
/// deleted.
Future<List<String>> extractBundle(String zipPath, Directory directory) {
  final dirPath = directory.path;
  return Isolate.run(() {
    final input = InputFileStream(zipPath);
    final maxBytes = input.length;
    final written = <String>[];
    var writtenBytes = 0;
    try {
      final Archive archive;
      try {
        archive = ZipDecoder().decodeStream(input);
      } catch (e) {
        throw BundleFormatException('Not a zip: $e');
      }
      final files = archive.files.where((f) => f.isFile).toList();
      if (files.isEmpty) {
        throw const BundleFormatException('No files');
      }
      if (files.any((f) => f.compression != CompressionType.none)) {
        throw const BundleFormatException('Compressed entries');
      }
      if (files.fold<int>(0, (sum, f) => sum + f.size) > maxBytes) {
        throw const BundleFormatException('Larger than the zip');
      }
      for (final file in files) {
        final name = uniqueFileName(
          sanitizeFileName(file.name),
          (candidate) => File('$dirPath/$candidate').existsSync(),
        );
        final path = '$dirPath/$name';
        written.add(path);
        final output = OutputFileStream(path);
        try {
          file.writeContent(output);
          writtenBytes += output.length;
        } finally {
          output.closeSync();
        }
        // The sizes in the zip's directory may not match the data.
        if (writtenBytes > maxBytes) {
          throw const BundleFormatException('Larger than the zip');
        }
      }
      return written;
    } catch (_) {
      for (final path in written) {
        final file = File(path);
        if (file.existsSync()) file.deleteSync();
      }
      rethrow;
    } finally {
      input.closeSync();
    }
  });
}
