import 'dart:io';

import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/model/image_compression_settings.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static int defaultMtu = 2935;
  static int defaultFps = 20;

  /// iPhones can't focus closer than about 15 cm; zooming in fills the frame
  /// with the code from a distance they can focus at.
  static double get defaultCameraZoom => Platform.isIOS ? 1.25 : 1.0;

  /// iPhones read codes more reliably at 1080p.
  static ResolutionPreset get defaultCameraResolution =>
      Platform.isIOS ? ResolutionPreset.veryHigh : ResolutionPreset.high;

  static String? _localeId;
  static ThemeMode? _theme;
  static int? _mtu;
  static int? _playbackFps;
  static bool? _animations;
  static bool? _pureBlack;
  static Color? _accentColor;
  static ImageCompressionSettings? _imageCompressionSettings;
  static ResolutionPreset? _cameraResolution;
  static int? _cameraFps;
  static double? _cameraZoom;
  static bool? _debugVideoHdr;
  static double? _debugExposureMs;
  static bool? _hapticFeedback;
  static bool? _soundFeedback;
  static bool? _acousticDetection;
  static bool? _multipleQrCodes;
  static bool? _hasSeenMicPrompt;
  static bool? _alwaysCompressImages;

  static Locale? get locale => _localeId == null ? null : Locale(_localeId!);
  static ThemeMode get theme => _theme ?? ThemeMode.system;
  static int get mtu => _mtu ?? defaultMtu;
  static int get playbackFps => _playbackFps ?? 20;
  static bool get animations => _animations ?? true;
  static bool get pureBlack => _pureBlack ?? false;
  static Color get accentColor => _accentColor ?? accentColorOptions[0];
  static ImageCompressionSettings get imageCompressionSettings =>
      _imageCompressionSettings ?? ImageCompressionSettings.defaultSettings;
  static ResolutionPreset get cameraResolution =>
      _cameraResolution ?? defaultCameraResolution;
  /// Null for the camera's default.
  static int? get cameraFps => _cameraFps;
  static double get cameraZoom => _cameraZoom ?? defaultCameraZoom;
  static bool get debugVideoHdr => _debugVideoHdr ?? false;
  static double? get debugExposureMs => _debugExposureMs;
  static bool get hapticFeedback => _hapticFeedback ?? false;
  static bool get soundFeedback => _soundFeedback ?? true;
  static bool get acousticDetection => _acousticDetection ?? false;
  static bool get multipleQrCodes => _multipleQrCodes ?? false;
  static bool get hasSeenMicPrompt => _hasSeenMicPrompt ?? false;
  static bool get alwaysCompressImages => _alwaysCompressImages ?? true;

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

  static Future<void> setPlaybackFps(int fps) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setInt('playback_fps', fps);
    _playbackFps = fps;
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
    _imageCompressionSettings = settings;
  }

  static Future<void> setCameraResolution(ResolutionPreset resolution) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setInt('camera_resolution', resolution.index);
    _cameraResolution = resolution;
  }

  static Future<void> setCameraFps(int? value) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    if (value == null) {
      sp.remove('cameraFps');
    } else {
      sp.setInt('cameraFps', value);
    }
    _cameraFps = value;
  }

  static Future<void> setCameraZoom(double value) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setDouble('cameraZoom', value);
    _cameraZoom = value;
  }

  static Future<void> setDebugVideoHdr(bool value) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setBool('debugVideoHdr', value);
    _debugVideoHdr = value;
  }

  static Future<void> setDebugExposureMs(double? value) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    if (value == null) {
      sp.remove('debugExposure');
    } else {
      sp.setDouble('debugExposure', value);
    }
    _debugExposureMs = value;
  }

  static Future<void> setHapticFeedback(bool value) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setBool('hapticFeedback', value);
    _hapticFeedback = value;
  }

  static Future<void> setSoundFeedback(bool value) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setBool('soundFeedback', value);
    _soundFeedback = value;
  }

  static Future<void> setAcousticDetection(bool value) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setBool('acousticDetection', value);
    _acousticDetection = value;
  }

  static Future<void> setMultipleQrCodes(bool value) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setBool('multipleQrCodes', value);
    _multipleQrCodes = value;
  }

  static Future<void> setHasSeenMicPrompt(bool value) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setBool('hasSeenMicPrompt', value);
    _hasSeenMicPrompt = value;
  }

  static Future<void> setAlwaysCompressImages(bool value) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setBool('alwaysCompressImages', value);
    _alwaysCompressImages = value;
  }

  static Future<void> read() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    _localeId = sp.getString('locale_id');
    _theme = ThemeMode.values.byName(sp.getString('theme') ?? 'system');
    _mtu = sp.getInt('mtu') ?? defaultMtu;
    _playbackFps = sp.getInt('playback_fps') ?? 20;
    _animations = sp.getBool('animations') ?? true;
    _pureBlack = sp.getBool('pureBlack') ?? false;
    _accentColor = Color(
      sp.getInt('accentColor') ?? accentColorOptions[0].toARGB32(),
    );
    _imageCompressionSettings = ImageCompressionSettings.parseSafely(
      sp.getString('ic_settings'),
    );
    _cameraResolution =
        sp.getInt('camera_resolution') != null
            ? ResolutionPreset.values[sp.getInt('camera_resolution')!]
            : defaultCameraResolution;
    _cameraFps = sp.getInt('cameraFps');
    _cameraZoom = sp.getDouble('cameraZoom') ?? defaultCameraZoom;
    _debugVideoHdr = sp.getBool('debugVideoHdr') ?? false;
    _debugExposureMs = sp.getDouble('debugExposure');
    _hapticFeedback = sp.getBool('hapticFeedback') ?? false;
    _soundFeedback = sp.getBool('soundFeedback') ?? true;
    _acousticDetection = sp.getBool('acousticDetection') ?? false;
    _multipleQrCodes = sp.getBool('multipleQrCodes') ?? false;
    _hasSeenMicPrompt = sp.getBool('hasSeenMicPrompt') ?? false;
    _alwaysCompressImages = sp.getBool('alwaysCompressImages') ?? true;
  }
}
