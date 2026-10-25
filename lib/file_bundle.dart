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
/// Only stored (uncompressed) entries are accepted, so the output can't be
/// larger than the zip. On any error, files written so far are deleted.
Future<List<String>> extractBundle(String zipPath, Directory directory) {
  final dirPath = directory.path;
  return Isolate.run(() {
    final input = InputFileStream(zipPath);
    final written = <String>[];
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
        } finally {
          output.closeSync();
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
