import 'dart:io';

import 'package:flutter/services.dart';

const _channel = MethodChannel('blastqr/files');

/// Opens the system file manager (Finder, Explorer, ...) with [file]
/// selected. Desktop only.
Future<void> revealInFileManager(File file) async {
  final path = file.absolute.path;
  if (Platform.isMacOS) {
    // Native, since the sandbox keeps the app from running `open -R`.
    await _channel.invokeMethod('revealInFinder', path);
  } else if (Platform.isWindows) {
    await Process.run('explorer.exe', ['/select,', path]);
  } else if (Platform.isLinux) {
    await _revealOnLinux(file);
  }
}

/// Most Linux file managers can select a file through the freedesktop
/// FileManager1 interface. Without it, opens the folder instead.
Future<void> _revealOnLinux(File file) async {
  try {
    final result = await Process.run('dbus-send', [
      '--session',
      '--print-reply',
      '--dest=org.freedesktop.FileManager1',
      '--type=method_call',
      '/org/freedesktop/FileManager1',
      'org.freedesktop.FileManager1.ShowItems',
      'array:string:${Uri.file(file.absolute.path)}',
      'string:',
    ]);
    if (result.exitCode == 0) return;
  } on ProcessException {
    // No dbus-send.
  }
  await Process.run('xdg-open', [file.parent.path]);
}
