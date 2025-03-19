import 'package:blast_qr/theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const int defaultMtu = 1252;

  static String? _localeId;
  static BlastTheme? _theme;
  static int? _mtu;

  static Locale? get locale => _localeId == null ? null : Locale(_localeId!);
  static BlastTheme get theme => _theme ?? BlastTheme.system;
  static int get mtu => _mtu ?? defaultMtu;

  static setLocale(String? localeId) async {
    if (localeId == null) {
      return;
    }
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString('locale_id', localeId);
    _localeId = localeId;
  }

  static setTheme(BlastTheme theme) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString('theme', theme.name);
    _theme = theme;
  }

  static setMtu(int mtu) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setInt('mtu', mtu);
    _mtu = mtu;
  }

  static Future<void> read() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    _localeId = sp.getString('locale_id');
    _theme = BlastTheme.values.byName(sp.getString('theme') ?? 'system');
    _mtu = sp.getInt('mtu') ?? defaultMtu;
  }
}
