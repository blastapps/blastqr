import 'package:blast_qr/crypto/password.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('generatePassword', () {
    test('is 3 groups of 4 Crockford base32 characters', () {
      final format = RegExp(r'^[0-9A-HJKMNP-TV-Z]{4}(-[0-9A-HJKMNP-TV-Z]{4}){2}$');
      for (var i = 0; i < 200; i++) {
        expect(generatePassword(), matches(format));
      }
    });

    test('is different each time', () {
      final passwords = {for (var i = 0; i < 100; i++) generatePassword()};
      expect(passwords.length, 100);
    });

    test('normalizes to its 12 characters without dashes', () {
      final password = generatePassword();
      expect(normalizePassword(password), password.replaceAll('-', ''));
    });
  });

  group('normalizePassword', () {
    test('a generated code can be typed loosely', () {
      const canonical = 'K7M2QX9P4RTA';
      for (final typed in [
        'K7M2-QX9P-4RTA',
        'k7m2qx9p4rta',
        ' k7m2 qx9p 4rta ',
        'K7M2-QX9P-4rta',
      ]) {
        expect(normalizePassword(typed), canonical, reason: typed);
      }
    });

    test('O, I and L are read as 0, 1 and 1', () {
      expect(normalizePassword('OOOO-IIII-LLLL'), '000011111111');
    });

    test('custom passwords are only trimmed', () {
      expect(normalizePassword('  My Secret  '), 'My Secret');
      expect(normalizePassword('hunter2'), 'hunter2');
      // 12 characters, but U isn't in the alphabet: stays exact.
      expect(normalizePassword('uuuuuuuuuuuu'), 'uuuuuuuuuuuu');
      // Right alphabet, wrong length.
      expect(normalizePassword('abcd-efgh'), 'abcd-efgh');
    });
  });

  group('custom passwords', () {
    test('generated codes are recognised, custom ones are not', () {
      expect(isGeneratedCode(generatePassword()), isTrue);
      expect(isGeneratedCode('k7m2 qx9p 4rta'), isTrue);
      expect(isGeneratedCode('My Secret'), isFalse);
    });

    test('formatPassword groups a code in fours', () {
      expect(formatPassword('k7m2qx9p4rta'), 'K7M2-QX9P-4RTA');
    });

    test('formatPassword leaves custom passwords alone', () {
      expect(formatPassword('My Secret'), 'My Secret');
    });
  });
}
