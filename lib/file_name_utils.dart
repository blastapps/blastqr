import 'dart:io';

/// Returns a unique file name within [directory] based on [fileName].
/// If [fileName] already exists, appends an incrementing counter like `name(1).ext`.
Future<String> resolveUniqueFileName(
  Directory directory,
  String fileName,
) async {
  if (!await File('${directory.path}/$fileName').exists()) {
    return fileName;
  }

  final dotIndex = fileName.lastIndexOf('.');
  final name = dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
  final ext = dotIndex > 0 ? fileName.substring(dotIndex) : '';

  var counter = 1;
  while (true) {
    final candidate = '$name($counter)$ext';
    if (!await File('${directory.path}/$candidate').exists()) {
      return candidate;
    }
    counter++;
  }
}
