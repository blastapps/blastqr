import 'package:flutter/services.dart';

/// Native calls used by the debug page.
abstract final class DebugChannel {
  static const _channel = MethodChannel('blastqr/debug');

  static final Future<String> deviceModel = _channel
      .invokeMethod<String>('deviceModel')
      .then((model) => model ?? '-');

  /// Android only. What the back camera lets apps request; a frame rate
  /// missing here is ignored by the camera.
  static final Future<String> backCameraFpsRanges = _channel
      .invokeListMethod<List<Object?>>('backCameraFpsRanges')
      .then((ranges) {
        final labels = {
          for (final r in ranges ?? const <List<Object?>>[])
            r[0] == r[1] ? '${r[0]}' : '${r[0]}-${r[1]}',
        };
        return labels.isEmpty ? 'None reported' : labels.join(', ');
      });

  /// iOS only. Live exposure and focus of the back camera.
  static Future<CameraSample?> cameraState() async {
    final map = await _channel.invokeMapMethod<String, Object?>('cameraState');
    return map == null ? null : CameraSample._(map);
  }
}

class CameraSample {
  CameraSample._(Map<String, Object?> map)
    : exposureMs = map['exposureMs'] as double,
      exposureLimitMs = map['exposureLimitMs'] as double,
      iso = map['iso'] as double,
      exposureBias = map['exposureBias'] as double,
      exposureMode = map['exposureMode'] as String,
      focusMode = map['focusMode'] as String,
      lensPosition = map['lensPosition'] as double,
      zoom = map['zoom'] as double,
      videoHdr = map['videoHDR'] as bool,
      videoHdrSupported = map['videoHDRSupported'] as bool,
      adjustingFocus = map['adjustingFocus'] as bool,
      minFocusDistanceMm = map['minFocusDistanceMm'] as int?,
      format = map['format'] as String,
      minFps = map['minFps'] as double,
      maxFps = map['maxFps'] as double;

  final double exposureMs;
  final double exposureLimitMs;
  final double iso;
  final double exposureBias;
  final String exposureMode;
  final String focusMode;

  /// 0 is the closest the lens can focus, 1 the furthest.
  final double lensPosition;
  final double zoom;
  final bool videoHdr;
  final bool videoHdrSupported;
  final bool adjustingFocus;
  final int? minFocusDistanceMm;
  final String format;
  final double minFps;
  final double maxFps;
}
