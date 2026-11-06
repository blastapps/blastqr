import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

const _channel = MethodChannel('blastqr/files');

/// Where the app keeps its temp files. Desktop temp directories are shared
/// with other apps, so there it's a folder of our own.
Future<Directory> appTempDirectory() async {
  final temp = await getTemporaryDirectory();
  if (Platform.isIOS || Platform.isAndroid) return temp;
  return Directory('${temp.path}/blastqr').create(recursive: true);
}

/// A new temp directory for files shared into the app.
Future<Directory> createSharedFilesDirectory() async =>
    (await appTempDirectory()).createTemp('shared_');

/// Moves a file the share extension (iOS) or share intent (Android) copied
/// for us into [directory], so it can be deleted later.
Future<File> takeSharedFile(String path, Directory directory) => moveFile(
  File(path),
  '${directory.path}/${File(path).uri.pathSegments.last}',
);

/// Moves [file] to [target], copying when a rename can't cross volumes.
Future<File> moveFile(File file, String target) async {
  try {
    return await file.rename(target);
  } on FileSystemException {
    final copy = await file.copy(target);
    await file.delete();
    return copy;
  }
}

/// Deletes copies of files left by earlier sessions: files shared or picked
/// to send, and unfinished receives. [keep] is a temp directory still in use.
Future<void> clearTempFiles({Directory? keep}) async {
  final temp = await appTempDirectory();
  await for (final entity in temp.list()) {
    if (entity.path == keep?.path) continue;
    await _delete(entity);
  }

  if (Platform.isIOS) {
    final path = await _channel.invokeMethod<String>('sharedContainerPath');
    if (path == null) return;
    // Only visible files: the container also holds the share extension's
    // settings and a hidden iOS metadata file.
    await for (final entity in Directory(path).list()) {
      if (entity is! File || entity.uri.pathSegments.last.startsWith('.')) {
        continue;
      }
      await _delete(entity);
    }
  }
}

Future<void> _delete(FileSystemEntity entity) async {
  try {
    await entity.delete(recursive: true);
  } on FileSystemException catch (_) {}
}
