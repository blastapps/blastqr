import 'dart:io';

import 'package:blast_qr/temp_files.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';

const _channel = MethodChannel('blastqr/files');

/// Lets the user pick files to send. Empty if they cancelled.
///
/// On Android, file_selector reads each file into memory, which runs out on
/// large files, so our own picker copies them into a temp directory instead.
Future<List<File>> pickFiles() async {
  if (!Platform.isAndroid) {
    final files = await openFiles(
      acceptedTypeGroups: const [XTypeGroup(label: 'files')],
    );
    return [for (final file in files) File(file.path)];
  }
  final directory = await (await appTempDirectory()).createTemp('picked_');
  final paths =
      await _channel.invokeListMethod<String>('pickFiles', directory.path) ??
      const [];
  return [for (final path in paths) File(path)];
}
