import 'dart:convert';
import 'dart:io';

/// Longest name we produce, in UTF-8 bytes. Filesystems allow 255; the rest
/// leaves room for the `(n)` suffix added by [resolveUniqueFileName].
const int _maxFileNameBytes = 200;

const String _fallbackFileName = 'file';

/// Characters that are path separators or invalid on common filesystems.
final RegExp _forbiddenChars = RegExp(r'[<>:"/\\|?*\x00-\x1F\x7F]');

/// Turns an untrusted name (received over QR or typed by the user) into a
/// plain file name that can't point outside the directory it's joined to.
///
/// - Keeps only the last path segment (`../../a.txt` → `a.txt`).
/// - Removes separators, control characters and characters invalid on
///   Windows/macOS.
/// - Removes leading dots (no `..`, no hidden files) and surrounding spaces.
/// - Limits the length, keeping the extension when possible.
/// - Returns `file` (plus [fallbackExtension], if given) when nothing usable
///   is left.
String sanitizeFileName(String input, {String? fallbackExtension}) {
  final name = _cleanSegment(input);
  if (name.isNotEmpty) {
    return _truncateUtf8(name, _maxFileNameBytes);
  }

  final ext = _cleanSegment(fallbackExtension ?? '');
  return ext.isEmpty ? _fallbackFileName : '$_fallbackFileName.$ext';
}

/// Last path segment, without forbidden characters, leading dots or
/// surrounding spaces. May be empty.
String _cleanSegment(String input) {
  final lastSegment = input.split(RegExp(r'[/\\]')).last;
  final name = lastSegment.replaceAll(_forbiddenChars, '').trim();
  return name.replaceFirst(RegExp(r'^\.+'), '').trim();
}

/// Shortens [name] to at most [maxBytes] UTF-8 bytes, cutting the base name
/// rather than the extension and never splitting a character.
String _truncateUtf8(String name, int maxBytes) {
  if (utf8.encode(name).length <= maxBytes) return name;

  final dotIndex = name.lastIndexOf('.');
  final hasExt = dotIndex > 0 && name.length - dotIndex <= 16;
  final ext = hasExt ? name.substring(dotIndex) : '';
  var base = hasExt ? name.substring(0, dotIndex) : name;

  final budget = maxBytes - utf8.encode(ext).length;
  final runes = base.runes.toList();
  while (runes.isNotEmpty &&
      utf8.encode(String.fromCharCodes(runes)).length > budget) {
    runes.removeLast();
  }
  base = String.fromCharCodes(runes).trim();
  return base.isEmpty ? '$_fallbackFileName$ext' : '$base$ext';
}

/// Returns a unique file name within [directory] based on [fileName].
/// If [fileName] already exists, appends an incrementing counter like `name(1).ext`.
///
/// [fileName] must already be a plain name (see [sanitizeFileName]).
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
