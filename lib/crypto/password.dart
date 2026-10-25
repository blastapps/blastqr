import 'dart:math';

/// Crockford base32: no I, L, O or U, so a code read aloud or retyped is
/// hard to get wrong.
const _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

const generatedPasswordLength = 12;

const minRecommendedPasswordLength = 8;

String generatePassword() {
  final random = Random.secure();
  final code = String.fromCharCodes(
    List.generate(
      generatedPasswordLength,
      (_) => _alphabet.codeUnitAt(random.nextInt(_alphabet.length)),
    ),
  );
  return formatPassword(code);
}

String formatPassword(String password) {
  final code = _asCode(password);
  if (code == null) return password;
  return [
    for (var i = 0; i < code.length; i += 4) code.substring(i, i + 4),
  ].join('-');
}

bool isGeneratedCode(String password) => _asCode(password) != null;

/// A generated code can be typed loosely: any case, with or without dashes
/// or spaces, and O/I/L for 0/1/1. Custom passwords are only trimmed.
String normalizePassword(String password) =>
    _asCode(password) ?? password.trim();

String? _asCode(String password) {
  final buffer = StringBuffer();
  for (final rune in password.trim().toUpperCase().runes) {
    var c = String.fromCharCode(rune);
    if (c == '-' || c == ' ') continue;
    c = switch (c) {
      'O' => '0',
      'I' || 'L' => '1',
      _ => c,
    };
    if (!_alphabet.contains(c)) return null;
    buffer.write(c);
  }
  final code = buffer.toString();
  return code.length == generatedPasswordLength ? code : null;
}
