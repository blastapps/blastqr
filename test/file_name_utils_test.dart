import 'dart:convert';

import 'package:blast_qr/file_name_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sanitizeFileName', () {
    test('keeps ordinary names', () {
      expect(sanitizeFileName('photo.jpg'), 'photo.jpg');
      expect(sanitizeFileName('my file (2).pdf'), 'my file (2).pdf');
      expect(sanitizeFileName('사진.png'), '사진.png');
    });

    test('strips directory parts', () {
      expect(sanitizeFileName('../../Library/Preferences/x.plist'), 'x.plist');
      expect(sanitizeFileName(r'..\..\evil.txt'), 'evil.txt');
      expect(sanitizeFileName('/etc/passwd'), 'passwd');
    });

    test('rejects dot names and hidden files', () {
      expect(sanitizeFileName('..'), 'file');
      expect(sanitizeFileName('.'), 'file');
      expect(sanitizeFileName('../'), 'file');
      expect(sanitizeFileName('.hidden'), 'hidden');
    });

    test('removes control and forbidden characters', () {
      expect(sanitizeFileName('a\x00b\nc.txt'), 'abc.txt');
      expect(sanitizeFileName('what?<>:"|*.txt'), 'what.txt');
    });

    test('falls back when nothing is left', () {
      expect(sanitizeFileName(''), 'file');
      expect(sanitizeFileName('   '), 'file');
      expect(sanitizeFileName('..', fallbackExtension: 'jpg'), 'file.jpg');
      expect(sanitizeFileName('', fallbackExtension: '../'), 'file');
    });

    test('limits length and keeps the extension', () {
      final result = sanitizeFileName('${'a' * 300}.jpeg');
      expect(utf8.encode(result).length, lessThanOrEqualTo(200));
      expect(result, endsWith('.jpeg'));
    });

    test('does not split multi-byte characters when shortening', () {
      final result = sanitizeFileName('${'한' * 100}.txt');
      expect(utf8.encode(result).length, lessThanOrEqualTo(200));
      expect(result, endsWith('.txt'));
      expect(() => utf8.decode(utf8.encode(result)), returnsNormally);
    });
  });
}
