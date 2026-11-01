import 'dart:io';

import 'package:blast_qr/app_preferences.dart';
import 'package:blast_qr/file_name_utils.dart';
import 'package:blast_qr/model/scanned_qr_code.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

const _channel = MethodChannel('blastqr/files');

// Linux and Windows keep it in the user's own Documents folder, which may
// already have a folder called "Received".
final _name = Platform.isLinux || Platform.isWindows ? 'docs' : 'Received';

/// On iOS, Documents shows in the Files app, so received files stay in
/// Application Support unless the user turns on [AppPreferences.showInFilesApp].
Future<Directory> _directory({required bool visible}) async {
  final base = !Platform.isIOS || visible
      ? await getApplicationDocumentsDirectory()
      : await getApplicationSupportDirectory();
  return Directory('${base.path}/$_name');
}

Future<Directory> receivedFilesDirectory() async {
  final directory = await _directory(visible: AppPreferences.showInFilesApp);
  await directory.create(recursive: true);
  return directory;
}

/// Moves received files to where the setting points and keeps them and saved
/// QR codes out of iCloud backups.
Future<void> syncReceivedFiles() async {
  final directory = await receivedFilesDirectory();
  if (!Platform.isIOS) return;
  await _moveFiles(
    await _directory(visible: !AppPreferences.showInFilesApp),
    directory,
  );
  final qrCodes = await qrCodesDirectory();
  for (final dir in [directory, qrCodes]) {
    await dir.create(recursive: true);
    await _channel.invokeMethod('excludeFromBackup', dir.path);
  }
}

/// Moves the files in [from] into [to] and deletes [from].
Future<void> _moveFiles(Directory from, Directory to) async {
  if (!await from.exists()) return;
  await to.create(recursive: true);
  await for (final entity in from.list()) {
    if (entity is! File) continue;
    final name = await resolveUniqueFileName(to, entity.uri.pathSegments.last);
    await entity.rename('${to.path}/$name');
  }
  try {
    await from.delete();
  } on FileSystemException catch (_) {}
}
