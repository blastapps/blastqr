import 'dart:io';

import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/features/files_received/files_page.dart';
import 'package:blast_qr/features/home_tabs_page.dart';
import 'package:blast_qr/file_badge_count.dart';
import 'package:blast_qr/l10n/app_localizations.dart';
import 'package:blast_qr/nav_bar_visibility.dart';
import 'package:blast_qr/platform_support.dart';
import 'package:blast_qr/widgets/file_list_row.dart';
import 'package:blast_qr/widgets/selection_bar.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The desktop Received page: the file manager style list and its dialogs.
void main() {
  late Directory received;

  setUp(() {
    final documents = Directory.systemTemp.createTempSync('blastqr_test');
    received = Directory('${documents.path}/Received')..createSync();
    // Newest first: f0, f1, ...
    final now = DateTime.now();
    for (var i = 0; i < 4; i++) {
      File('${received.path}/f$i.txt')
        ..writeAsStringSync('x')
        ..setLastModifiedSync(now.subtract(Duration(minutes: i)));
    }
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => documents.path,
        );
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() => received.parent.deleteSync(recursive: true));

  /// Lets real file system work (loading, watching) finish.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pumpPage(
    WidgetTester tester, {
    Widget home = const FilesPage(),
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppSettings()),
          ChangeNotifierProvider(create: (_) => EncodeSettings()),
          ChangeNotifierProvider(create: (_) => FileBadgeCount(value: null)),
          ChangeNotifierProvider(create: (_) => NavBarVisibility()),
          ChangeNotifierProvider(create: (_) => SelectionBarController()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
    await settle(tester);
  }

  /// The home page's background never stops animating, so this waits a
  /// fixed time instead of for all animations to end.
  Future<void> step(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  List<String> selectedNames(WidgetTester tester) => [
    for (final row in tester.widgetList<FileListRow>(find.byType(FileListRow)))
      if (row.selected) row.name,
  ];

  testWidgets('dialogs open from the list and keys work after', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('f1.txt'), kind: PointerDeviceKind.mouse);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(find.text('f2.txt'), kind: PointerDeviceKind.mouse);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(selectedNames(tester), ['f1.txt', 'f2.txt']);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('2 files selected'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);

    // The list has focus back without being clicked.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(selectedNames(tester), ['f3.txt']);

    await tester.tap(
      find.text('f0.txt'),
      buttons: kSecondaryButton,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(selectedNames(tester), ['f0.txt']);
  }, skip: !isDesktopOS);

  testWidgets('the selection bar shows the count and opens or clears', (
    tester,
  ) async {
    await pumpPage(tester, home: const HomeTabsPage());
    await tester.tap(find.text('Received'));
    await settle(tester);
    expect(find.byType(SelectionBar), findsNothing);

    // One file: the arrow opens its own options.
    await tester.tap(find.text('f1.txt'), kind: PointerDeviceKind.mouse);
    await step(tester);
    expect(find.text('1 selected'), findsOneWidget);
    await tester.tap(
      find
          .descendant(
            of: find.byType(SelectionBar),
            matching: find.byType(IconButton),
          )
          .last,
    );
    await step(tester);
    expect(find.text('File options'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await step(tester);

    // Several: the arrow opens the dialog for all of them.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(find.text('f3.txt'), kind: PointerDeviceKind.mouse);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await step(tester);
    expect(find.text('3 selected'), findsOneWidget);
    await tester.tap(find.byType(SelectionBar));
    await step(tester);
    expect(find.text('3 files selected'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await step(tester);

    // Clear hides the bar.
    await tester.tap(find.byTooltip('Cancel'));
    await step(tester);
    expect(find.byType(SelectionBar), findsNothing);
    expect(selectedNames(tester), isEmpty);
  }, skip: !isDesktopOS);

  testWidgets('back clears the selection instead of leaving', (tester) async {
    await pumpPage(tester, home: const HomeTabsPage());
    await tester.tap(find.text('Received'));
    await settle(tester);
    await tester.tap(find.text('f1.txt'), kind: PointerDeviceKind.mouse);
    await step(tester);
    expect(find.byType(SelectionBar), findsOneWidget);

    // What Android's back button sends.
    final handled = await tester.binding.handlePopRoute();
    await step(tester);

    expect(handled, isTrue);
    expect(find.byType(SelectionBar), findsNothing);
    expect(selectedNames(tester), isEmpty);
    expect(find.byType(HomeTabsPage), findsOneWidget);
  }, skip: !isDesktopOS);

  testWidgets('touch works like on phones', (tester) async {
    await pumpPage(tester);

    // A tap opens the file.
    await tester.tap(find.text('f1.txt'));
    await tester.pumpAndSettle();
    expect(find.text('File options'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    // A long-press starts selecting, then taps add and remove.
    await tester.longPress(find.text('f1.txt'));
    await tester.tap(find.text('f3.txt'));
    await tester.pump();
    expect(selectedNames(tester), ['f1.txt', 'f3.txt']);
    await tester.tap(find.text('f1.txt'));
    await tester.pump();
    expect(selectedNames(tester), ['f3.txt']);
    expect(find.byType(Dialog), findsNothing);
  }, skip: !isDesktopOS);

  testWidgets('files changed by other apps show up', (tester) async {
    await pumpPage(tester);
    expect(find.text('f1.txt'), findsOneWidget);

    await tester.runAsync(() async {
      File('${received.path}/f1.txt').deleteSync();
      File('${received.path}/f2.txt').renameSync('${received.path}/moved.txt');
      File('${received.path}/new.txt').writeAsStringSync('y');
    });
    await settle(tester);

    expect(find.text('f1.txt'), findsNothing);
    expect(find.text('f2.txt'), findsNothing);
    expect(find.text('moved.txt'), findsOneWidget);
    expect(find.text('new.txt'), findsOneWidget);

    // Stops the folder watchers before the folder is deleted.
    await tester.pumpWidget(const SizedBox());
  }, skip: !isDesktopOS);
}
