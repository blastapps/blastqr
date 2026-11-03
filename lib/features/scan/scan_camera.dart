import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

/// Camera settings and details the camera plugin doesn't offer.
/// [configure] is iOS only.
abstract final class ScanCamera {
  static const _channel = MethodChannel('blastqr/camera');

  /// The iPhone exposes for up to 1/120 s and merges frames for video HDR.
  /// Either blends two QR codes into one frame whenever the sender changes
  /// code mid-capture, so both are kept short or off by default.
  static const defaultMaxExposureMs = 3.0;

  /// [maxExposureMs] caps automatic exposure, null leaves it uncapped.
  /// [exposureMs] fixes the exposure instead, for testing.
  /// Frame rates the back camera can be set to at [resolution]; empty when
  /// they can't be found out.
  static Future<List<int>> supportedFrameRates(ResolutionPreset resolution) {
    // The sizes the iOS camera plugin picks for each preset; 0 for the
    // largest format.
    final (width, height) = switch (resolution) {
      ResolutionPreset.low => (352, 288),
      ResolutionPreset.medium => (640, 480),
      ResolutionPreset.high => (1280, 720),
      ResolutionPreset.veryHigh => (1920, 1080),
      ResolutionPreset.ultraHigh => (3840, 2160),
      ResolutionPreset.max => (0, 0),
    };
    if (!Platform.isIOS && !Platform.isAndroid) return Future.value(const []);
    return _channel
        .invokeListMethod<int>('supportedFrameRates', {
          'width': width,
          'height': height,
        })
        .then((rates) => rates ?? const <int>[])
        .catchError((_) => const <int>[]);
  }

  /// Highest frame rate picked automatically. Every frame is copied from the
  /// camera to Dart, so the 120 and 240 FPS slow-motion modes some phones
  /// offer cost far too much to pick without asking.
  static int get maxAutoFps => 60;

  /// The highest supported rate up to [maxAutoFps], or null for the camera's
  /// default when the rates can't be found out.
  static Future<int?> highestFrameRate(ResolutionPreset resolution) async {
    final rates = (await supportedFrameRates(
      resolution,
    )).where((fps) => fps <= maxAutoFps);
    return rates.isEmpty ? null : rates.reduce(max);
  }

  static Future<void> configure({
    required bool videoHdr,
    required double? maxExposureMs,
    required double? exposureMs,
  }) => _channel.invokeMethod('configureScanCamera', {
    'videoHdr': videoHdr,
    'maxExposureMs': maxExposureMs,
    'exposureMs': exposureMs,
  });
}
