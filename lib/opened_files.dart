import 'package:flutter/services.dart';

const _channel = MethodChannel('blastqr/open_files');

/// Calls [onOpen] with the paths of files opened with the running app from
/// the desktop "Open with" menu. Returns the paths opened before Dart was
/// listening. macOS and Linux only: Windows opens a new instance instead.
Future<List<String>> listenForOpenedFiles(
  void Function(List<String> paths) onOpen,
) async {
  _channel.setMethodCallHandler((call) async {
    if (call.method == 'open') onOpen((call.arguments as List).cast<String>());
  });
  return await _channel.invokeListMethod<String>('ready') ?? [];
}
