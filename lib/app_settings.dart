import 'dart:developer';

import 'package:blast_qr/app_preferences.dart';
import 'package:blast_qr/model/image_compression_settings.dart';
import 'package:flutter/material.dart';

class AppSettings extends ChangeNotifier {
  Locale? locale;
  ThemeMode theme;
  bool animations;
  bool pureBlack;
  Color accentColor;
  ImageCompressionSettings imageCompressionSettings;

  AppSettings()
    : locale = AppPreferences.locale,
      theme = AppPreferences.theme,
      animations = AppPreferences.animations,
      pureBlack = AppPreferences.pureBlack,
      accentColor = AppPreferences.accentColor,
      imageCompressionSettings = AppPreferences.imageCompressionSettings;

  void updateLocale(String? localeId) {
    log('Setting locale to $localeId');
    locale = localeId == null ? null : Locale(localeId);
    AppPreferences.setLocale(localeId);
    notifyListeners();
  }

  void updateTheme(ThemeMode theme) {
    AppPreferences.setTheme(theme);
    this.theme = theme;
    notifyListeners();
  }

  void updateAnimationsEnabled(bool animations) {
    AppPreferences.setAnimationsEnabled(animations);
    this.animations = animations;
    notifyListeners();
  }

  void updatePureBlackEnabled(bool pureBlack) {
    AppPreferences.setPureBlackEnabled(pureBlack);
    this.pureBlack = pureBlack;
    notifyListeners();
  }

  void updateAccentColor(Color accentColor) {
    AppPreferences.setAccentColor(accentColor);
    this.accentColor = accentColor;
    notifyListeners();
  }

  void updateImageCompressionSettings(ImageCompressionSettings settings) {
    AppPreferences.setImageCompressionSettings(settings);
    imageCompressionSettings = settings;
    notifyListeners();
  }
}

class EncodeSettings extends ChangeNotifier {
  int mtu;

  EncodeSettings() : mtu = AppPreferences.mtu;

  void updateMtu(int mtu) {
    AppPreferences.setMtu(mtu); // Persist
    this.mtu = mtu;
    notifyListeners();
  }
}
