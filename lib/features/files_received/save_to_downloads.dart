import 'dart:io';

import 'package:media_scanner/media_scanner.dart';
import 'package:path/path.dart' as p;

const androidDownloadsPath = '/storage/emulated/0/Download';

/// Copies [file] into the Android Downloads folder and returns the new path.
/// If the name is taken, a timestamp is added to it.
Future<String> saveToDownloads(File file) async {
  final name = p.basename(file.path);
  var path = '$androidDownloadsPath/$name';
  // File.copy overwrites an existing file instead of failing.
  if (await File(path).exists()) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    path =
        '$androidDownloadsPath/${p.basenameWithoutExtension(name)}_$timestamp${p.extension(name)}';
  }
  await file.copy(path);
  MediaScanner.loadMedia(path: path);
  return path;
}
