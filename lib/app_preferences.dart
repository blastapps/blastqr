import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/model/image_compression_settings.dart';
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
  static ImageCompressionSettings? _imageCompressionSettings;

  static Locale? get locale => _localeId == null ? null : Locale(_localeId!);
  static ThemeMode get theme => _theme ?? ThemeMode.system;
  static int get mtu => _mtu ?? defaultMtu;
  static bool get animations => _animations ?? true;
  static bool get pureBlack => _pureBlack ?? false;
  static Color get accentColor => _accentColor ?? accentColorOptions[0];
  static ImageCompressionSettings get imageCompressionSettings =>
      _imageCompressionSettings ?? ImageCompressionSettings.defaultSettings;

  static Future<void> setLocale(String? localeId) async {
    if (localeId == null) {
      return;
    }
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString('locale_id', localeId);
    _localeId = localeId;
  }

  static Future<void> setTheme(ThemeMode theme) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString('theme', theme.name);
    _theme = theme;
  }

  static Future<void> setMtu(int mtu) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setInt('mtu', mtu);
    _mtu = mtu;
  }

  static Future<void> setPureBlackEnabled(bool pureBlack) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setBool('pureBlack', pureBlack);
    _pureBlack = pureBlack;
  }

  static Future<void> setAnimationsEnabled(bool animations) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setBool('animations', animations);
    _animations = animations;
  }

  static Future<void> setAccentColor(Color accentColor) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setInt('accentColor', accentColor.toARGB32());
    _accentColor = accentColor;
  }

  static Future<void> setImageCompressionSettings(
    ImageCompressionSettings settings,
  ) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString('ic_settings', settings.toJson());
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
    _imageCompressionSettings = ImageCompressionSettings.parseSafely(
      sp.getString('ic_settings'),
    );
  }
}
