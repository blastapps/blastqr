import 'dart:developer';

import 'package:blast_qr/app_preferences.dart';
import 'package:blast_qr/model/image_compression_settings.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class AppSettings extends ChangeNotifier {
  Locale? locale;
  ThemeMode theme;
  bool animations;
  bool pureBlack;
  Color accentColor;
  ImageCompressionSettings imageCompressionSettings;
  ResolutionPreset cameraResolution;
  bool hapticFeedback;
  bool soundFeedback;

  AppSettings()
    : locale = AppPreferences.locale,
      theme = AppPreferences.theme,
      animations = AppPreferences.animations,
      pureBlack = AppPreferences.pureBlack,
      accentColor = AppPreferences.accentColor,
      imageCompressionSettings = AppPreferences.imageCompressionSettings,
      cameraResolution = AppPreferences.cameraResolution,
      hapticFeedback = AppPreferences.hapticFeedback,
      soundFeedback = AppPreferences.soundFeedback;

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

  void updateCameraResolution(ResolutionPreset resolution) {
    AppPreferences.setCameraResolution(resolution);
    cameraResolution = resolution;
    notifyListeners();
  }

  void updateHapticFeedback(bool value) {
    AppPreferences.setHapticFeedback(value);
    hapticFeedback = value;
    notifyListeners();
  }

  void updateSoundFeedback(bool value) {
    AppPreferences.setSoundFeedback(value);
    soundFeedback = value;
    notifyListeners();
  }
}

class EncodeSettings extends ChangeNotifier {
  int mtu;
  int playbackFps;

  EncodeSettings()
    : mtu = AppPreferences.mtu,
      playbackFps = AppPreferences.playbackFps;

  void updateMtu(int mtu) {
    AppPreferences.setMtu(mtu);
    this.mtu = mtu;
    notifyListeners();
  }

  void updatePlaybackFps(int fps) {
    AppPreferences.setPlaybackFps(fps);
    playbackFps = fps;
    notifyListeners();
  }
}
