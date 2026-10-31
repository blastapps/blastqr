import 'dart:developer';
import 'dart:math' show min;

import 'package:blast_qr/app_preferences.dart';
import 'package:blast_qr/model/image_compression_settings.dart';
import 'package:blast_qr/received_files_directory.dart';
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

  /// Null for the camera's default.
  int? cameraFps;
  double cameraZoom;
  bool debugVideoHdr;

  /// Null for the default capped automatic exposure, 0 for uncapped, and
  /// otherwise a fixed exposure in ms.
  double? debugExposureMs;
  bool hapticFeedback;
  bool soundFeedback;
  bool acousticDetection;
  bool hasSeenMicPrompt;
  bool alwaysCompressImages;
  bool showInFilesApp;

  AppSettings()
    : locale = AppPreferences.locale,
      theme = AppPreferences.theme,
      animations = AppPreferences.animations,
      pureBlack = AppPreferences.pureBlack,
      accentColor = AppPreferences.accentColor,
      imageCompressionSettings = AppPreferences.imageCompressionSettings,
      cameraResolution = AppPreferences.cameraResolution,
      cameraFps = AppPreferences.cameraFps,
      cameraZoom = AppPreferences.cameraZoom,
      debugVideoHdr = AppPreferences.debugVideoHdr,
      debugExposureMs = AppPreferences.debugExposureMs,
      hapticFeedback = AppPreferences.hapticFeedback,
      soundFeedback = AppPreferences.soundFeedback,
      acousticDetection = AppPreferences.acousticDetection,
      hasSeenMicPrompt = AppPreferences.hasSeenMicPrompt,
      alwaysCompressImages = AppPreferences.alwaysCompressImages,
      showInFilesApp = AppPreferences.showInFilesApp;

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

  void updateCameraFps(int? value) {
    AppPreferences.setCameraFps(value);
    cameraFps = value;
    notifyListeners();
  }

  void updateCameraZoom(double value) {
    AppPreferences.setCameraZoom(value);
    cameraZoom = value;
    notifyListeners();
  }

  void updateDebugVideoHdr(bool value) {
    AppPreferences.setDebugVideoHdr(value);
    debugVideoHdr = value;
    notifyListeners();
  }

  void updateDebugExposureMs(double? value) {
    AppPreferences.setDebugExposureMs(value);
    debugExposureMs = value;
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

  void updateAcousticDetection(bool value) {
    AppPreferences.setAcousticDetection(value);
    acousticDetection = value;
    notifyListeners();
  }

  void updateHasSeenMicPrompt(bool value) {
    AppPreferences.setHasSeenMicPrompt(value);
    hasSeenMicPrompt = value;
    notifyListeners();
  }

  void updateAlwaysCompressImages(bool value) {
    AppPreferences.setAlwaysCompressImages(value);
    alwaysCompressImages = value;
    notifyListeners();
  }

  Future<void> updateShowInFilesApp(bool value) async {
    await AppPreferences.setShowInFilesApp(value);
    showInFilesApp = value;
    try {
      await syncReceivedFiles();
    } catch (error) {
      log('Failed to move received files: $error');
    }
    notifyListeners();
  }
}

class EncodeSettings extends ChangeNotifier {
  int mtu;
  int playbackFps;
  bool multipleQrCodes;
  bool optimizeSmallFiles;

  EncodeSettings()
    : mtu = AppPreferences.mtu,
      playbackFps = AppPreferences.playbackFps,
      multipleQrCodes = AppPreferences.multipleQrCodes,
      optimizeSmallFiles = AppPreferences.optimizeSmallFiles;

  bool _isOptimized(int fileSize) =>
      optimizeSmallFiles && fileSize <= AppPreferences.smallFileBytes;

  /// Smaller codes and a slower rate for small files, unless the user's
  /// settings are already lower.
  int mtuFor(int fileSize) =>
      _isOptimized(fileSize) ? min(mtu, AppPreferences.smallFileMtu) : mtu;

  int fpsFor(int fileSize) => _isOptimized(fileSize)
      ? min(playbackFps, AppPreferences.smallFileFps)
      : playbackFps;

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

  void updateMultipleQrCodes(bool value) {
    AppPreferences.setMultipleQrCodes(value);
    multipleQrCodes = value;
    notifyListeners();
  }

  void updateOptimizeSmallFiles(bool value) {
    AppPreferences.setOptimizeSmallFiles(value);
    optimizeSmallFiles = value;
    notifyListeners();
  }
}
