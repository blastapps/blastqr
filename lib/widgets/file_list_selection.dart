import 'dart:io';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Selection for a desktop list. With a mouse it works like a file manager:
/// click selects one item, Cmd/Ctrl-click toggles, Shift-click selects a
/// range and double-click opens. With touch (tablets, touchscreens) it works
/// like on phones: tap opens, long-press starts selecting. [move] steps
/// through the items for the arrow keys.
class FileListSelection<T> extends ChangeNotifier {
  FileListSelection(this._items);

  /// The items in the order they're shown.
  final List<T> Function() _items;

  final Set<T> _selected = {};
  // Where Shift ranges start.
  T? _anchor;
  // The item the arrow keys move from, which is kept scrolled into view.
  T? _cursor;
  // The last click, to detect double-clicks without delaying single clicks.
  T? _lastClicked;
  DateTime _lastClickTime = DateTime(0);
  PointerDeviceKind _pointerKind = PointerDeviceKind.mouse;

  /// Goes on the row of [cursor], so [move] can scroll it into view.
  final cursorKey = GlobalKey();

  /// For [FileListKeyboard]. Clicks take it, so the keys work after.
  final focusNode = FocusNode();

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  T? get cursor => _cursor;
  int get length => _selected.length;
  bool get isEmpty => _selected.isEmpty;
  bool get isNotEmpty => _selected.isNotEmpty;
  bool contains(T item) => _selected.contains(item);

  /// In the order they're shown.
  List<T> get selected => [
    for (final item in _items())
      if (_selected.contains(item)) item,
  ];

  void clear() {
    _selected.clear();
    _anchor = null;
    _cursor = null;
    notifyListeners();
  }

  void add(T item) {
    _selected.add(item);
    notifyListeners();
  }

  void toggle(T item) {
    _toggle(item);
    notifyListeners();
  }

  void _toggle(T item) {
    if (!_selected.remove(item)) _selected.add(item);
  }

  void _selectOnly(T item) {
    _selected
      ..clear()
      ..add(item);
  }

  /// Called by [FileListKeyboard] for each press, to tell mouse from touch.
  void trackPointer(PointerDownEvent event) => _pointerKind = event.kind;

  bool get _isTouch => switch (_pointerKind) {
    PointerDeviceKind.touch ||
    PointerDeviceKind.stylus ||
    PointerDeviceKind.invertedStylus => true,
    _ => false,
  };

  /// A row tap. With a mouse it selects with the modifier keys and calls
  /// [open] on a double-click. With touch it calls [open] right away, or
  /// adds to and removes from a selection that was started.
  void tap(T item, void Function(List<T> items) open) {
    focusNode.requestFocus();
    if (_isTouch) {
      if (isEmpty) {
        open([item]);
      } else {
        toggle(item);
      }
      return;
    }
    if (_click(item)) open([item]);
  }

  /// A long-press, with touch, starts selecting.
  void longPress(T item) {
    focusNode.requestFocus();
    _toggle(item);
    _anchor = _cursor = item;
    notifyListeners();
  }

  /// A right-click opens the whole selection when [item] is part of it,
  /// otherwise selects and opens just [item].
  void secondaryTap(T item, void Function(List<T> items) open) {
    focusNode.requestFocus();
    if (_selected.length > 1 && _selected.contains(item)) {
      open(selected);
      return;
    }
    _selectOnly(item);
    _anchor = _cursor = item;
    notifyListeners();
    open([item]);
  }

  /// Returns true for a plain double-click.
  bool _click(T item) {
    final keyboard = HardwareKeyboard.instance;
    final toggle = Platform.isMacOS
        ? keyboard.isMetaPressed
        : keyboard.isControlPressed;
    final range = keyboard.isShiftPressed;
    final now = DateTime.now();
    final doubleClick =
        item == _lastClicked &&
        now.difference(_lastClickTime) < kDoubleTapTimeout;
    // A third click starts over instead of counting as another double-click.
    _lastClicked = doubleClick ? null : item;
    _lastClickTime = now;

    final items = _items();
    final anchorIndex = _anchor == null ? -1 : items.indexOf(_anchor as T);
    if (range && anchorIndex != -1) {
      _selectRange(items, anchorIndex, items.indexOf(item));
      _cursor = item;
    } else {
      if (toggle) {
        _toggle(item);
      } else {
        _selectOnly(item);
      }
      _anchor = _cursor = item;
    }
    notifyListeners();
    return doubleClick && !toggle && !range;
  }

  bool canMove(int step) {
    final items = _items();
    if (_cursor == null) return items.isNotEmpty;
    final next = items.indexOf(_cursor as T) + step;
    return next >= 0 && next < items.length;
  }

  /// Selects the next or previous item, or with [extend] grows the range
  /// from the anchor. Starts at either end when nothing is selected.
  void move(int step, {bool extend = false}) {
    final items = _items();
    if (items.isEmpty) return;
    final current = _cursor == null ? -1 : items.indexOf(_cursor as T);
    final index = current == -1
        ? (step > 0 ? 0 : items.length - 1)
        : (current + step).clamp(0, items.length - 1);
    final item = items[index];
    final anchorIndex = _anchor == null ? -1 : items.indexOf(_anchor as T);
    _cursor = item;
    if (extend && anchorIndex != -1) {
      _selectRange(items, anchorIndex, index);
    } else {
      _selectOnly(item);
      _anchor = item;
    }
    notifyListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final row = cursorKey.currentContext;
      if (row == null || !row.mounted) return;
      Scrollable.ensureVisible(
        row,
        alignmentPolicy: step > 0
            ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
            : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    });
  }

  void _selectRange(List<T> items, int from, int to) {
    _selected
      ..clear()
      ..addAll(items.sublist(min(from, to), max(from, to) + 1));
  }
}

/// The keys and clicks around a desktop file list: tells mouse from touch
/// for [FileListSelection.tap], and arrows and Tab move the
/// selection (Shift+arrows grow it), Space or Enter open it, and Esc or a
/// click on empty space clears it. Tab past the first or last item falls
/// through to the normal focus traversal.
class FileListKeyboard<T> extends StatelessWidget {
  const FileListKeyboard({
    super.key,
    required this.selection,
    required this.onOpen,
    required this.child,
    this.autofocus = false,
  });

  final FileListSelection<T> selection;
  final void Function(List<T> items) onOpen;
  final Widget child;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: selection.trackPointer,
      child: Focus(
        focusNode: selection.focusNode,
        autofocus: autofocus,
        onKeyEvent: _onKey,
        // A click on empty space clears, like in a file manager.
        child: GestureDetector(
          onTap: () {
            if (!selection._isTouch) selection.clear();
          },
          child: child,
        ),
      ),
    );
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    // Other controls inside the list (like filter chips) keep their keys.
    if (!node.hasPrimaryFocus || event is KeyUpEvent) {
      return KeyEventResult.ignored;
    }
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isMetaPressed ||
        keyboard.isControlPressed ||
        keyboard.isAltPressed) {
      return KeyEventResult.ignored;
    }
    final shift = keyboard.isShiftPressed;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      selection.move(1, extend: shift);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      selection.move(-1, extend: shift);
    } else if (key == LogicalKeyboardKey.tab) {
      final step = shift ? -1 : 1;
      if (!selection.canMove(step)) return KeyEventResult.ignored;
      selection.move(step);
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space) {
      if (event is! KeyRepeatEvent && selection.isNotEmpty) {
        onOpen(selection.selected);
      }
    } else if (key == LogicalKeyboardKey.escape) {
      selection.clear();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }
}
