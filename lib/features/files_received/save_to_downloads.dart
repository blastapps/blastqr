import 'dart:io';

import 'package:media_scanner/media_scanner.dart';
import 'package:path/path.dart' as p;

const androidDownloadsPath = '/storage/emulated/0/Download';

/// Copies [file] into the Android Downloads folder and returns the new path.
/// If the name is taken, a timestamp is added to it.
Future<String> saveToDownloads(File file) async {
  final name = p.basename(file.path);
  try {
    return await _copy(file, name);
  } on PathExistsException {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return _copy(
      file,
      '${p.basenameWithoutExtension(name)}_$timestamp${p.extension(name)}',
    );
  }
}

Future<String> _copy(File file, String name) async {
  final path = '$androidDownloadsPath/$name';
  await file.copy(path);
  MediaScanner.loadMedia(path: path);
  return path;
}
