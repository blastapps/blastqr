import 'dart:io';

import 'package:blast_qr/widgets/file_list_selection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The key that adds to or removes from a selection: Cmd on macOS, else Ctrl.
final _toggleKey = Platform.isMacOS
    ? LogicalKeyboardKey.metaLeft
    : LogicalKeyboardKey.controlLeft;

void main() {
  late List<String> items;
  late FileListSelection<String> selection;
  late List<List<String>> opened;

  setUp(() {
    items = ['a', 'b', 'c', 'd', 'e'];
    selection = FileListSelection<String>(() => items);
    opened = [];
  });

  tearDown(() => selection.dispose());

  void open(List<String> items) => opened.add(items);

  Future<void> tapWith(
    WidgetTester tester,
    LogicalKeyboardKey key,
    String item,
  ) async {
    await tester.sendKeyDownEvent(key);
    selection.tap(item, open);
    await tester.sendKeyUpEvent(key);
  }

  testWidgets('a click selects only that item', (tester) async {
    selection.tap('b', open);
    selection.tap('d', open);

    expect(selection.selected, ['d']);
    expect(opened, isEmpty);
  });

  testWidgets('Cmd/Ctrl-click adds and removes items', (tester) async {
    selection.tap('a', open);
    await tapWith(tester, _toggleKey, 'c');
    await tapWith(tester, _toggleKey, 'a');

    expect(selection.selected, ['c']);
  });

  testWidgets('Shift-click selects the range from the last click', (
    tester,
  ) async {
    selection.tap('d', open);
    await tapWith(tester, LogicalKeyboardKey.shiftLeft, 'b');

    expect(selection.selected, ['b', 'c', 'd']);
  });

  testWidgets('a double-click opens the item, a third click does not', (
    tester,
  ) async {
    selection.tap('c', open);
    selection.tap('c', open);
    selection.tap('c', open);

    expect(opened, [
      ['c'],
    ]);
  });

  testWidgets('a right-click inside a multi-selection opens all of it', (
    tester,
  ) async {
    selection.tap('a', open);
    await tapWith(tester, LogicalKeyboardKey.shiftLeft, 'c');
    selection.secondaryTap('b', open);

    expect(opened, [
      ['a', 'b', 'c'],
    ]);
    expect(selection.selected, ['a', 'b', 'c']);
  });

  testWidgets('a right-click elsewhere selects and opens just that item', (
    tester,
  ) async {
    selection.tap('a', open);
    await tapWith(tester, LogicalKeyboardKey.shiftLeft, 'c');
    selection.secondaryTap('e', open);

    expect(opened, [
      ['e'],
    ]);
    expect(selection.selected, ['e']);
  });

  testWidgets('moving starts at either end and stops at the edges', (
    tester,
  ) async {
    selection.move(1);
    expect(selection.selected, ['a']);
    expect(selection.canMove(-1), isFalse);

    selection.clear();
    selection.move(-1);
    expect(selection.selected, ['e']);
    expect(selection.canMove(1), isFalse);

    selection.move(1);
    expect(selection.selected, ['e']);
  });

  testWidgets('moving with extend grows and shrinks the range', (tester) async {
    selection.tap('b', open);
    selection.move(1, extend: true);
    selection.move(1, extend: true);
    expect(selection.selected, ['b', 'c', 'd']);

    selection.move(-1, extend: true);
    expect(selection.selected, ['b', 'c']);
  });

  testWidgets('selected follows the shown order and skips hidden items', (
    tester,
  ) async {
    selection.tap('d', open);
    await tapWith(tester, _toggleKey, 'a');
    items = ['d', 'c'];

    expect(selection.selected, ['d']);
  });

  group('touch', () {
    setUp(
      () => selection.trackPointer(
        const PointerDownEvent(kind: PointerDeviceKind.touch),
      ),
    );

    test('a tap opens the item', () {
      selection.tap('b', open);

      expect(opened, [
        ['b'],
      ]);
      expect(selection.isEmpty, isTrue);
    });

    test('a long-press starts selecting, then taps toggle', () {
      selection.longPress('b');
      selection.tap('d', open);
      selection.tap('b', open);

      expect(selection.selected, ['d']);
      expect(opened, isEmpty);
    });
  });

  group('FileListKeyboard', () {
    Future<void> pumpList(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              FileListKeyboard<String>(
                selection: selection,
                autofocus: true,
                onOpen: open,
                child: const SizedBox(height: 100, width: 100),
              ),
              // The next stop for Tab after the list.
              TextButton(onPressed: () {}, child: const Text('next')),
            ],
          ),
        ),
      );
    }

    testWidgets('arrows select, Enter opens and Esc clears', (tester) async {
      await pumpList(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(selection.selected, ['b', 'c']);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(opened, [
        ['b', 'c'],
      ]);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(selection.isEmpty, isTrue);
    });

    testWidgets('Tab moves through the items, then leaves the list', (
      tester,
    ) async {
      await pumpList(tester);

      for (final item in items) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        expect(selection.selected, [item]);
      }
      expect(selection.focusNode.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(selection.focusNode.hasPrimaryFocus, isFalse);
      expect(selection.selected, ['e']);
    });

    testWidgets('Enter does nothing without a selection', (tester) async {
      await pumpList(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);

      expect(opened, isEmpty);
    });
  });
}
