import 'dart:io';

import 'package:blast_qr/features/send/widgets/file_header_widget.dart';
import 'package:blast_qr/features/send/widgets/file_too_large_alert_widget.dart';
import 'package:blast_qr/l10n/app_localizations.dart';
import 'package:blast_qr/model/file_type.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

FileWrapper _pdf(int size) => FileWrapper(
  file: File('doc.pdf'),
  type: FileType(extension: 'pdf', mimeType: 'application/pdf'),
  size: size,
  modified: DateTime(2026),
);

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  ),
);

Finder _text(String text) => find.textContaining(text, findRichText: true);

void main() {
  group('long transfer warning', () {
    Future<void> pumpAlert(
      WidgetTester tester, {
      int transferBytes = 2400000,
      int compressibleImages = 0,
    }) => _pump(
      tester,
      FileTooLargeAlertWidget(
        transferBytes: transferBytes,
        compressibleImages: compressibleImages,
        onAcknowledge: () {},
        onRequestCompressedImage: (_) {},
      ),
    );

    testWidgets('estimates the time at the slowest speed', (tester) async {
      // 2400 KB at 8 KB/s is 300 s.
      await pumpAlert(tester);

      expect(_text(' 5 minutes '), findsOneWidget);
    });

    testWidgets('only offers sending as is without images', (tester) async {
      await pumpAlert(tester);

      expect(find.text('Send anyway'), findsOneWidget);
      expect(find.text('Send compressed'), findsNothing);
      expect(_text('lower quality'), findsNothing);
    });

    testWidgets('offers compressing one image', (tester) async {
      await pumpAlert(tester, compressibleImages: 1);

      expect(find.text('Send compressed'), findsOneWidget);
      expect(_text('this image?'), findsOneWidget);
    });

    testWidgets('offers compressing several images', (tester) async {
      await pumpAlert(tester, compressibleImages: 3);

      expect(find.text('Send compressed'), findsOneWidget);
      expect(_text('these 3 images?'), findsOneWidget);
    });
  });

  group('header', () {
    testWidgets('shows the total size of several files', (tester) async {
      await _pump(
        tester,
        FileHeaderWidget(
          files: [_pdf(4000000), _pdf(5000000), _pdf(3155000)],
          onTapDismiss: () {},
        ),
      );

      expect(find.text('Sending 3 files'), findsOneWidget);
      expect(find.text('12155 KB'), findsOneWidget);
    });

    testWidgets('shows the compressed size next to the total', (tester) async {
      await _pump(
        tester,
        FileHeaderWidget(
          files: [_pdf(4000000), _pdf(5000000)],
          compressedSize: 2500000,
          onTapDismiss: () {},
        ),
      );

      expect(find.text('9000 KB'), findsOneWidget);
      expect(find.text('2500 KB'), findsOneWidget);
    });

    testWidgets('hides an unchanged compressed size', (tester) async {
      await _pump(
        tester,
        FileHeaderWidget(
          files: [_pdf(4000000)],
          compressedSize: 4000000,
          onTapDismiss: () {},
        ),
      );

      expect(find.text('doc.pdf'), findsOneWidget);
      expect(find.text('4000 KB'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsNothing);
    });
  });
}
