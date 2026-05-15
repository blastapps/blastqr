import 'package:flutter/foundation.dart';

class NavBarVisibility extends ChangeNotifier {
  bool _visible = true;

  bool get visible => _visible;

  void show() {
    if (!_visible) {
      _visible = true;
      notifyListeners();
    }
  }

  void hide() {
    if (_visible) {
      _visible = false;
      notifyListeners();
    }
  }
}
