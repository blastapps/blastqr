import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/features/settings/receiving_settings_page.dart';
import 'package:blast_qr/features/settings/settings_page.dart';
import 'package:blast_qr/l10n/app_localizations.dart';
import 'package:blast_qr/widgets/circle_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Wide windows show the settings pages in a pane with its own navigator,
  // while dialogs open above it on the app's navigator.
  testWidgets('closing a dialog keeps the settings pane', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    // The test font is much wider than the real one; at full size the links
    // under the settings list don't fit their narrow column.
    tester.platformDispatcher.textScaleFactorTestValue = 0.5;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppSettings()),
          ChangeNotifierProvider(create: (_) => EncodeSettings()),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsPage(),
        ),
      ),
    );
    await tester.tap(find.text('Receiving'));
    await tester.pumpAndSettle();

    final restore = find.descendant(
      of: find.byType(ReceivingSettingsPage),
      matching: find.byType(CircleButton),
    );
    await tester.tap(restore);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Restore'));
    await tester.pumpAndSettle();

    expect(find.text('Are you sure', findRichText: true), findsNothing);
    expect(find.byType(ReceivingSettingsPage), findsOneWidget);
  });
}
