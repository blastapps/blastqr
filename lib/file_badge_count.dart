import 'package:flutter/material.dart';

class FileBadgeCount extends ChangeNotifier {
  int? value;

  FileBadgeCount({required this.value});

  void add() {
    value = (value ?? 0) + 1;
    notifyListeners();
  }

  void subtract() {
    value = (value ?? 1) - 1;
    if (value == 0) {
      value = null;
    }
    notifyListeners();
  }

  void clear() {
    value = null;
    notifyListeners();
  }
}
