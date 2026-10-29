import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// A regular (non-transfer) QR code the user saved after scanning, stored as
/// a text file whose modified time is the scan date.
class ScannedQrCode {
  final File file;
  final String text;
  final DateTime scanned;

  int get size => utf8.encode(text).length;

  /// Short codes are well under 1 KB, so they show in bytes.
  String get sizeLabel =>
      size < 1000 ? '$size B' : '${(size / 1000).toStringAsFixed(0)} KB';

  ScannedQrCode({
    required this.file,
    required this.text,
    required this.scanned,
  });
}

/// On iOS, Documents shows in the Files app, so codes go in Application
/// Support instead.
Future<Directory> qrCodesDirectory() async {
  final base = Platform.isIOS
      ? await getApplicationSupportDirectory()
      : await getApplicationDocumentsDirectory();
  return Directory('${base.path}/qr_codes');
}

/// Where iOS kept codes before they moved to Application Support.
Future<Directory> legacyQrCodesDirectory() async {
  final documents = await getApplicationDocumentsDirectory();
  return Directory('${documents.path}/qr_codes');
}

Future<ScannedQrCode> saveScannedQrCode(
  String text,
  Directory directory,
) async {
  await directory.create(recursive: true);
  final file = File(
    '${directory.path}/${DateTime.now().microsecondsSinceEpoch}.txt',
  );
  await file.writeAsString(text, flush: true);
  return ScannedQrCode(
    file: file,
    text: text,
    scanned: await file.lastModified(),
  );
}

/// Newest first.
Future<List<ScannedQrCode>> loadScannedQrCodes(Directory directory) async {
  if (!await directory.exists()) return [];
  final files = directory.listSync().whereType<File>().where(
    (f) => f.path.endsWith('.txt'),
  );
  final codes = <ScannedQrCode>[];
  for (final file in files) {
    try {
      codes.add(
        ScannedQrCode(
          file: file,
          text: await file.readAsString(),
          scanned: await file.lastModified(),
        ),
      );
    } catch (_) {}
  }
  return codes..sort((l, r) => r.scanned.compareTo(l.scanned));
}
