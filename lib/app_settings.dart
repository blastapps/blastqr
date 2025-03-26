import 'dart:developer';
import 'package:blast_qr/app_preferences.dart';
import 'package:blast_qr/theme.dart';
import 'package:flutter/material.dart';

class AppSettings extends ChangeNotifier {
  Locale? locale;
  BlastTheme theme;

  AppSettings() : locale = AppPreferences.locale, theme = AppPreferences.theme;

  void updateLocale(String? localeId) {
    log('Setting locale to $localeId');
    locale = localeId == null ? null : Locale(localeId);
    AppPreferences.setLocale(localeId);
    notifyListeners();
  }

  void updateTheme(BlastTheme theme) {
    AppPreferences.setTheme(theme);
    this.theme = theme;
    notifyListeners();
  }
}

class EncodeSettings extends ChangeNotifier {
  int mtu;
  bool compress;

  EncodeSettings()
    : mtu = AppPreferences.mtu,
      compress = AppPreferences.compress;

  void updateMtu(int mtu) {
    AppPreferences.setMtu(mtu); // Persist
    this.mtu = mtu;
    notifyListeners();
  }

  void updateCompress(bool compress) {
    AppPreferences.setCompress(compress); // Persist
    this.compress = compress;
    notifyListeners();
  }
}
