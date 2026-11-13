import 'dart:io';

import 'package:flutter/services.dart';

const _channel = MethodChannel('blastqr/files');

/// iOS: lets the user pick a folder in the Files app to copy [files] into.
/// Returns how many were saved, 0 if the user cancelled.
Future<int> saveToFiles(List<File> files) async {
  final saved = await _channel.invokeMethod<int>('saveToFiles', [
    for (final f in files) f.absolute.path,
  ]);
  return saved ?? 0;
}
