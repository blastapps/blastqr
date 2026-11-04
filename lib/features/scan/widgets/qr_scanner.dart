import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:blast_qr/features/scan/scan_camera.dart';
import 'package:blast_qr/platform_support.dart';
import 'package:camera/camera.dart' hide ImageFormat;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_zxing/flutter_zxing.dart';

/// Camera preview that scans every frame for QR codes, using flutter_zxing
/// only as the decoder. Owning the camera lets us pick its frame rate, zoom
/// and orientation, and time each decode.
class QrScanner extends StatefulWidget {
  const QrScanner({
    super.key,
    required this.resolution,
    required this.onCodes,
    this.fps,
    this.zoom = 1.0,
    this.autoRestart = true,
    this.onCameraChanged,
    this.onFrame,
  });

  final ResolutionPreset resolution;

  /// Null picks the highest supported rate, see [ScanCamera.highestFrameRate].
  final int? fps;

  /// Starting zoom, clamped to what the camera supports. Pinching starts here.
  final double zoom;

  /// Whether the camera may reopen when nothing is read for a while. Off while
  /// the page isn't scanning, such as when a sheet covers the preview.
  final bool autoRestart;

  /// Codes read from one frame; never empty.
  final void Function(Codes codes) onCodes;

  /// The camera once it's ready, or null once it's closed.
  final void Function(CameraController? controller)? onCameraChanged;

  /// Every camera frame, after [onCodes], with how long decoding it took, or
  /// with null when it was skipped because the previous one was still decoding.
  final void Function(Duration? decodeTime, CameraImage image)? onFrame;

  @override
  State<QrScanner> createState() => QrScannerState();
}

class QrScannerState extends State<QrScanner> with WidgetsBindingObserver {
  // Teardown blocks opening the next camera, so no step may wait forever on
  // an unresponsive platform.
  static const _teardownTimeout = Duration(seconds: 2);

  // When the sender shows codes at the camera's frame rate, every frame can
  // land on a code change and read nothing until the timing shifts. Seen on a
  // Galaxy S22 at 30 FPS. Reopening the camera restarts its frame timing. The
  // wait doubles while nothing is read, so a camera pointed at no code isn't
  // reopened every few seconds. Once enough different codes were read the
  // timing works, so the camera is kept until it's reopened for another reason.
  static const _firstRestartAfter = Duration(seconds: 3);
  static const _maxRestartAfter = Duration(seconds: 6);
  static const _keepAfterCodes = 40;
  Duration _restartAfter = _firstRestartAfter;
  final _sinceLastCode = Stopwatch();
  final _differentCodes = <String>{};

  CameraController? _controller;

  /// Bumped whenever a camera is opened or closed, so callbacks from an older
  /// one (late frames, a slow initialize) know to do nothing.
  int _generation = 0;

  bool _decoding = false;
  bool _closedForLifecycle = false;
  Codes _results = Codes();

  double _zoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _pinchStartZoom = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _zoom = widget.zoom;
    // The camera doesn't wait for the decoder: frames that arrive before it's
    // ready are skipped.
    unawaited(
      zx.startCameraProcessing().catchError(
        (Object e) => debugPrint('QrScanner: decoder failed to start: $e'),
      ),
    );
    _open();
  }

  @override
  void didUpdateWidget(QrScanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resolution != widget.resolution ||
        oldWidget.fps != widget.fps) {
      _open();
    } else if (oldWidget.zoom != widget.zoom) {
      _setZoom(widget.zoom);
    }
    if (widget.autoRestart && !oldWidget.autoRestart) {
      _restartAfter = _firstRestartAfter;
      _sinceLastCode.reset();
    }
  }

  /// Reopens the camera, for when its frame timing keeps landing on code
  /// changes.
  void restart() {
    _restartAfter = _firstRestartAfter;
    unawaited(_open());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_closedForLifecycle) {
          _closedForLifecycle = false;
          _open();
        }
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _closeForLifecycle();
      // A desktop window goes inactive whenever it loses focus, and reopening
      // the camera takes about a second.
      case AppLifecycleState.inactive:
        if (!isDesktopOS) _closeForLifecycle();
      case AppLifecycleState.detached:
        break;
    }
  }

  // Also cancels a camera that's still starting, for example behind the
  // camera permission prompt, which makes the app inactive.
  void _closeForLifecycle() {
    _closedForLifecycle = true;
    _close();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _close(notify: false);
    zx.stopCameraProcessing();
    super.dispose();
  }

  Future<void> _open() async {
    await _close();
    final generation = _generation;
    bool isCurrent() => mounted && generation == _generation;

    final CameraController controller;
    try {
      final cameras = await availableCameras();
      final fps =
          widget.fps ?? await ScanCamera.highestFrameRate(widget.resolution);
      if (!isCurrent() || cameras.isEmpty) return;
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      controller = CameraController(
        camera,
        widget.resolution,
        enableAudio: false,
        fps: fps,
        // Frames the decoder can read directly: luminance first on Android,
        // BGRA on iOS. Left unset, some Android devices deliver NV21.
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.unknown,
      );
    } catch (e) {
      debugPrint('QrScanner: no camera: $e');
      return;
    }

    try {
      await controller.initialize();
      if (!isCurrent()) {
        unawaited(controller.dispose());
        return;
      }
      _controller = controller;
      await _lockOrientation(controller);
      await _readZoomRange(controller);
      if (!isCurrent()) return;
      _sinceLastCode
        ..reset()
        ..start();
      _differentCodes.clear();
      await controller.startImageStream((image) => _onImage(image, generation));
      if (!isCurrent()) return;
      setState(() {});
      widget.onCameraChanged?.call(controller);

      // On some devices the first start doesn't take.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (isCurrent() && !controller.value.isStreamingImages) {
        await controller.startImageStream(
          (image) => _onImage(image, generation),
        );
      }
    } catch (e) {
      debugPrint('QrScanner: camera setup failed: $e');
      if (isCurrent()) await _close();
    }
  }

  /// The camera follows the phone's physical orientation even though the UI
  /// is locked to portrait, which would turn the preview when held sideways.
  /// iPads run the UI in landscape and rotate it, so they keep following.
  Future<void> _lockOrientation(CameraController controller) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (Platform.isIOS && MediaQuery.sizeOf(context).shortestSide >= 600) {
      return;
    }
    try {
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
    } catch (e) {
      debugPrint('QrScanner: orientation lock failed: $e');
    }
  }

  Future<void> _readZoomRange(CameraController controller) async {
    try {
      _minZoom = await controller.getMinZoomLevel();
      _maxZoom = await controller.getMaxZoomLevel();
    } catch (e) {
      _minZoom = _maxZoom = 1.0;
    }
    if (_maxZoom < _minZoom) _minZoom = _maxZoom = 1.0;
    await _setZoom(_zoom);
  }

  Future<void> _setZoom(double zoom) async {
    _zoom = zoom.clamp(_minZoom, _maxZoom);
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      await controller.setZoomLevel(_zoom);
    } catch (e) {
      debugPrint('QrScanner: zoom failed: $e');
    }
  }

  /// [notify] rebuilds first so `CameraPreview`, which listens to the
  /// controller, leaves the tree before the controller is disposed. Otherwise
  /// stopping the stream schedules a preview rebuild on a disposed controller.
  /// It also tells [QrScanner.onCameraChanged]. Neither is allowed from
  /// [dispose].
  Future<void> _close({bool notify = true}) async {
    _generation++;
    _decoding = false;
    final controller = _controller;
    if (controller == null) return;
    _controller = null;
    _results = Codes();
    if (notify && mounted) {
      setState(() {});
      widget.onCameraChanged?.call(null);
    }

    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream().timeout(_teardownTimeout);
      }
    } catch (e) {
      debugPrint('QrScanner: stopImageStream failed: $e');
    }
    try {
      await controller.dispose().timeout(_teardownTimeout);
    } catch (e) {
      debugPrint('QrScanner: dispose failed: $e');
    }
  }

  bool _reportedUnreadableFormat = false;

  Future<void> _onImage(CameraImage image, int generation) async {
    if (generation != _generation || !mounted) return;
    if (_decoding) {
      widget.onFrame?.call(null, image);
      return;
    }
    _decoding = true;
    try {
      final imageFormat = cameraImageFormat(image);
      if (imageFormat == ImageFormat.none) {
        if (!_reportedUnreadableFormat) {
          _reportedUnreadableFormat = true;
          debugPrint(
            'QrScanner: unreadable frame format ${image.format.group}',
          );
        }
        return;
      }
      final stopwatch = Stopwatch()..start();
      final codes = await zx.processCameraImageMulti(
        image,
        DecodeParams(
          imageFormat: imageFormat,
          format: Format.qrCode,
          width: image.width,
          height: image.height,
          tryRotate: false,
          isMultiScan: true,
        ),
      );
      final decodeTime = stopwatch.elapsed;
      if (generation != _generation || !mounted) return;

      if (codes.codes.isEmpty &&
          widget.autoRestart &&
          (Platform.isAndroid || Platform.isIOS) &&
          _differentCodes.length < _keepAfterCodes &&
          _sinceLastCode.elapsed > _restartAfter) {
        debugPrint('QrScanner: nothing read for $_restartAfter, restarting');
        _restartAfter = _restartAfter * 2 > _maxRestartAfter
            ? _maxRestartAfter
            : _restartAfter * 2;
        unawaited(_open());
        return;
      }
      if (codes.codes.isNotEmpty) {
        _sinceLastCode.reset();
        _restartAfter = _firstRestartAfter;
        if (_differentCodes.length < _keepAfterCodes) {
          for (final code in codes.codes) {
            _differentCodes.add(
              code.text ?? String.fromCharCodes(code.rawBytes ?? const []),
            );
          }
        }
        widget.onCodes(codes);
        if (!mounted) return;
        setState(() => _results = codes);
      } else if (_results.codes.isNotEmpty) {
        // Take the last outlines off the screen.
        setState(() => _results = Codes());
      }
      widget.onFrame?.call(decodeTime, image);
    } catch (e) {
      debugPrint('QrScanner: decode failed: $e');
    } finally {
      if (generation == _generation) _decoding = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const ColoredBox(color: Colors.black, child: SizedBox.expand());
    }
    final preview = CameraPreview(
      controller,
      child: _results.codes.isEmpty
          ? null
          : _CodeOutlineOverlay(codes: _results.codes, controller: controller),
    );
    if (!Platform.isAndroid && !Platform.isIOS) {
      return ColoredBox(
        color: Colors.black,
        child: SizedBox.expand(child: Center(child: preview)),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final media = MediaQuery.sizeOf(context);
        final side = max(
          constraints.hasBoundedWidth ? constraints.maxWidth : media.width,
          constraints.hasBoundedHeight ? constraints.maxHeight : media.height,
        );
        // The preview covers the box, centered. ScanPage's tap-to-focus maps
        // taps onto the frame assuming this layout.
        return Stack(
          children: [
            SizedBox(
              width: side,
              height: side,
              child: ClipRect(
                child: OverflowBox(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(width: side, child: preview),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: GestureDetector(
                onScaleStart: (_) => _pinchStartZoom = _zoom,
                onScaleUpdate: (details) {
                  if (details.pointerCount < 2) return;
                  _setZoom(_pinchStartZoom * details.scale);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CodeOutlineOverlay extends StatelessWidget {
  const _CodeOutlineOverlay({required this.codes, required this.controller});

  final List<Code> codes;
  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: RotatedBox(
        quarterTurns: _quarterTurns(),
        child: CustomPaint(
          painter: _CodeOutlinePainter(
            codes: codes,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }

  // Matches flutter_zxing's MultiResultOverlay rotation.
  int _quarterTurns() {
    if (!Platform.isAndroid) return 0;
    return switch (controller.value.deviceOrientation) {
      DeviceOrientation.portraitUp || DeviceOrientation.portraitDown => 1,
      DeviceOrientation.landscapeRight => 2,
      DeviceOrientation.landscapeLeft => 0,
    };
  }
}

class _CodeOutlinePainter extends CustomPainter {
  _CodeOutlinePainter({required this.codes, required this.color});

  final List<Code> codes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    for (final code in codes) {
      final pos = code.position;
      if (pos == null) continue;
      final scale = size.width / pos.imageWidth;
      final path = Path()
        ..moveTo(pos.topLeftX * scale, pos.topLeftY * scale)
        ..lineTo(pos.topRightX * scale, pos.topRightY * scale)
        ..lineTo(pos.bottomRightX * scale, pos.bottomRightY * scale)
        ..lineTo(pos.bottomLeftX * scale, pos.bottomLeftY * scale)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_CodeOutlinePainter oldDelegate) => true;
}
