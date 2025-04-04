import 'package:blast_qr/color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static int defaultMtu = 2935;

  static String? _localeId;
  static ThemeMode? _theme;
  static int? _mtu;
  static bool? _animations;
  static bool? _pureBlack;
  static Color? _accentColor;

  static Locale? get locale => _localeId == null ? null : Locale(_localeId!);
  static ThemeMode get theme => _theme ?? ThemeMode.system;
  static int get mtu => _mtu ?? defaultMtu;
  static bool get animations => _animations ?? true;
  static bool get pureBlack => _pureBlack ?? false;
  static Color get accentColor => _accentColor ?? accentColorOptions[0];

  static setLocale(String? localeId) async {
    if (localeId == null) {
      return;
    }
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString('locale_id', localeId);
    _localeId = localeId;
  }

  static setTheme(ThemeMode theme) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString('theme', theme.name);
    _theme = theme;
  }

  static setMtu(int mtu) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setInt('mtu', mtu);
    _mtu = mtu;
  }

  static setPureBlackEnabled(bool pureBlack) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setBool('pureBlack', pureBlack);
    _pureBlack = pureBlack;
  }

  static setAnimationsEnabled(bool animations) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setBool('animations', animations);
    _animations = animations;
  }

  static setAccentColor(Color accentColor) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setInt('accentColor', accentColor.toARGB32());
    _accentColor = accentColor;
  }

  static Future<void> read() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    _localeId = sp.getString('locale_id');
    _theme = ThemeMode.values.byName(sp.getString('theme') ?? 'system');
    _mtu = sp.getInt('mtu') ?? defaultMtu;
    _animations = sp.getBool('animations') ?? true;
    _pureBlack = sp.getBool('pureBlack') ?? false;
    _accentColor = Color(
      sp.getInt('accentColor') ?? accentColorOptions[0].toARGB32(),
    );
  }
}
