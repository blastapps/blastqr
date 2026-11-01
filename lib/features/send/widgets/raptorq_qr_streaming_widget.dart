import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:blast_qr/features/send/helpers/file_qr_encoder.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blast_qr/model/image_compression_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Decides when the QR codes change, based on elapsed time.
class RaptorQrStreamingWidgetController with ChangeNotifier {
  int _fps = 20;

  /// Time since playback started, and the point the current fps applies from.
  Duration _elapsed = Duration.zero;
  Duration _fpsOrigin = Duration.zero;

  /// Frames played before the last fps change.
  int _baseFrames = 0;
  int _lastFrames = -1;

  /// How many times the codes have changed.
  int get framesAdvanced =>
      _baseFrames + math.max(0, _framesSinceOrigin.floor());

  double get _framesSinceOrigin =>
      (_elapsed - _fpsOrigin).inMicroseconds * _fps / 1e6;

  bool _stopped = false;

  /// Freezes playback on the current frames.
  void stopAnimation() {
    _stopped = true;
  }

  /// Starts timing from zero. Called by the widget when playback begins.
  void start(int fps) {
    _stopped = false;
    _fps = fps;
    _elapsed = Duration.zero;
    _fpsOrigin = Duration.zero;
    _baseFrames = 0;
    _lastFrames = -1;
  }

  /// Changes fps without jumping: frames already played are kept. The next
  /// tick repaints.
  void setFps(int fps) {
    _baseFrames = framesAdvanced;
    _fpsOrigin = _elapsed;
    _fps = fps;
    _lastFrames = -1;
  }

  /// Called on every screen refresh by the widget's ticker. Time-based, so
  /// a pause (app in background) skips ahead instead of bursting frames.
  void tick(Duration elapsed) {
    if (_stopped) return;
    _elapsed = elapsed;
    final frames = framesAdvanced;
    if (frames != _lastFrames) {
      _lastFrames = frames;
      notifyListeners();
    }
  }
}

class RaptorQrStreamingWidget extends StatefulWidget {
  final RaptorQrStreamingWidgetController controller;
  final FileWrapper file;
  final int mtu;
  final int fps;
  final ImageCompressionSettings? imageCompressionSettings;

  final String? password;

  final String? fileName;

  final bool isBundle;

  final bool fill;
  final Function()? onTap;
  final void Function(int)? onStart;

  /// Called once per stream when the frames shown reach
  /// [nearlyCompleteFraction] of the frames needed with no loss (K).
  final VoidCallback? onNearlyComplete;

  static const double nearlyCompleteFraction = 0.8;

  const RaptorQrStreamingWidget({
    super.key,
    required this.file,
    required this.mtu,
    required this.fps,
    required this.controller,
    required this.imageCompressionSettings,
    this.password,
    this.fileName,
    this.isBundle = false,
    this.fill = true,
    this.onTap,
    this.onStart,
    this.onNearlyComplete,
  });

  @override
  State<RaptorQrStreamingWidget> createState() =>
      _RaptorQrStreamingWidgetState();
}

class _RaptorQrStreamingWidgetState extends State<RaptorQrStreamingWidget>
    with SingleTickerProviderStateMixin {
  late int _fps;
  late final Ticker _ticker = createTicker(widget.controller.tick);

  QrFrameSource? _source;
  StreamSubscription<QrPixelData>? _frameSub;

  /// Bumped on every (re)start so late callbacks from an old source are
  /// ignored.
  int _generation = 0;

  /// Rendered frames waiting to be shown, by sequence number.
  final Map<int, ui.Image> _ready = {};

  /// Sequence number of the next frame to show. Frames are shown strictly in
  /// order, so every frame on screen is one the receiver hasn't seen yet.
  int _nextSeq = 0;

  bool _nearlyCompleteReported = false;

  /// What each grid cell shows, and how many times the controller has told
  /// it to change.
  final List<ui.Image?> _cellImages = [];
  final List<int?> _cellSeqs = [];
  final List<int> _cellAdvanced = [];

  /// Number of cells in the last layout (1 when not in fill mode).
  int _cellCount = 1;

  @override
  void initState() {
    super.initState();
    _fps = widget.fps;
    widget.controller.addListener(_onControllerTick);
    init();
  }

  @override
  void didUpdateWidget(covariant RaptorQrStreamingWidget oldWidget) {
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerTick);
      widget.controller.addListener(_onControllerTick);
    }
    if (oldWidget.file != widget.file) {
      init();
    }
    if (oldWidget.fps != widget.fps) {
      _fps = widget.fps;
      _applyFps();
    }
    super.didUpdateWidget(oldWidget);
  }

  Future<void> init() async {
    final generation = ++_generation;
    _ticker.stop();
    _releaseFrames();
    if (mounted) setState(() {});

    debugPrint('Generating QR codes..');

    final source = await FileQrEncoder.start(
      widget.file,
      widget.mtu,
      icSettings: widget.imageCompressionSettings,
      password: widget.password,
      fileName: widget.fileName,
      isBundle: widget.isBundle,
      onCompressedSize: widget.onStart,
    );
    if (!mounted || generation != _generation) {
      source.dispose();
      return;
    }
    _source = source;
    _frameSub = source.frames.listen(
      (frame) => _decodeFrame(generation, frame),
    );
  }

  void _decodeFrame(int generation, QrPixelData frame) {
    ui.decodeImageFromPixels(
      frame.pixels,
      frame.moduleCount,
      frame.moduleCount,
      ui.PixelFormat.rgba8888,
      (image) {
        if (!mounted || generation != _generation) {
          image.dispose();
          return;
        }
        _ready[frame.seq] = image;
        if (!_ticker.isActive && frame.seq == 0) {
          _startPlayback();
        } else {
          // Fill cells that are still empty right away.
          _onControllerTick();
        }
      },
    );
  }

  void _startPlayback() {
    widget.controller.start(_fps);
    _ticker
      ..stop()
      ..start();
    _onControllerTick();
    setState(() {});
  }

  void _applyFps() {
    if (_ticker.isActive) widget.controller.setFps(_fps);
  }

  /// Gives each cell whose turn it is to change the next new frame. If that
  /// frame isn't rendered yet, the cell keeps its current one until it is.
  void _onControllerTick() {
    if (!mounted || _source == null) return;
    _resizeCells(_cellCount);

    var changed = false;
    for (var cell = 0; cell < _cellCount; cell++) {
      final advanced = widget.controller.framesAdvanced;
      final due = advanced != _cellAdvanced[cell] || _cellImages[cell] == null;
      if (!due) continue;

      final image = _ready.remove(_nextSeq);
      if (image == null) break; // Rendering is behind: show the rest later.
      _cellImages[cell]?.dispose();
      _cellImages[cell] = image;
      _cellSeqs[cell] = _nextSeq;
      _cellAdvanced[cell] = advanced;
      _nextSeq++;
      changed = true;
    }

    if (changed) {
      _source?.markConsumed(_nextSeq);
      setState(() {});
      _reportNearlyComplete();
    }
  }

  void _reportNearlyComplete() {
    final sourceCount = _source?.sourceCount;
    if (_nearlyCompleteReported || sourceCount == null) return;
    final threshold =
        (sourceCount * RaptorQrStreamingWidget.nearlyCompleteFraction).ceil();
    if (_nextSeq >= threshold) {
      _nearlyCompleteReported = true;
      widget.onNearlyComplete?.call();
    }
  }

  void _resizeCells(int count) {
    while (_cellImages.length > count) {
      _cellImages.removeLast()?.dispose();
      _cellSeqs.removeLast();
      _cellAdvanced.removeLast();
    }
    while (_cellImages.length < count) {
      _cellImages.add(null);
      _cellSeqs.add(null);
      _cellAdvanced.add(-1);
    }
  }

  void _releaseFrames() {
    _frameSub?.cancel();
    _frameSub = null;
    _source?.dispose();
    _source = null;
    for (final image in _ready.values) {
      image.dispose();
    }
    _ready.clear();
    for (final image in _cellImages) {
      image?.dispose();
    }
    _cellImages.clear();
    _cellSeqs.clear();
    _cellAdvanced.clear();
    _nextSeq = 0;
    _nearlyCompleteReported = false;
  }

  @override
  void dispose() {
    _generation++;
    widget.controller.removeListener(_onControllerTick);
    _ticker.dispose();
    _releaseFrames();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ticker.isActive) {
      return SizedBox(
        width: double.infinity,
        child: Column(
          spacing: 8,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator.adaptive(
              backgroundColor: Colors.black,
            ),
            Text(
              context.l10n.generating_codes,
              style: const TextStyle(color: Colors.black),
            ),
          ],
        ),
      );
    }
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
        builder: (context, c) {
          final qrSize = c.maxWidth > c.maxHeight ? c.maxHeight : c.maxWidth;
          final hOffset = c.maxWidth > (c.maxHeight - 20) ? 12 : 0;
          final vOffset = c.maxWidth > (c.maxHeight - 20) ? 20 : 8;
          final double adaptedPadding = widget.fill ? 8 : 16;

          if (widget.fill) {
            return _FlexibleGrid(
              constraints: c,
              itemBuilder: (gridIndex, totalCount) {
                // Read by the next tick; cells are filled from there.
                _cellCount = totalCount;
                final img = gridIndex < _cellImages.length
                    ? _cellImages[gridIndex]
                    : null;
                // Own layer per code: a change repaints only that code.
                return RepaintBoundary(
                  child: CustomPaint(
                    painter: img != null ? _QrImagePainter(img) : null,
                  ),
                );
              },
            );
          }

          _cellCount = 1;
          final uiImage = _cellImages.isNotEmpty ? _cellImages[0] : null;
          final seq = _cellSeqs.isNotEmpty ? _cellSeqs[0] : null;
          final sourceCount = _source?.sourceCount;
          return Column(
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(16, adaptedPadding, 16, 0),
                height: qrSize - vOffset,
                width: qrSize - hOffset,
                child: CustomPaint(
                  painter: uiImage != null ? _QrImagePainter(uiImage) : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Frame number / frames the receiver needs (K).
                    Text(
                      seq == null || sourceCount == null
                          ? ''
                          : '${seq + 1}/$sourceCount',
                      style: const TextStyle(
                        color: Colors.black,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      '${_fps}FPS',
                      style: const TextStyle(color: Colors.black),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Two rows of 1–3 square codes, by the screen's aspect ratio. The codes
/// are as large as fits, with a fixed gap, centered as one block so a camera
/// can frame them all.
class _FlexibleGrid extends StatelessWidget {
  const _FlexibleGrid({required this.constraints, required this.itemBuilder});

  static const _rows = 2;
  static const _spacing = 16.0;

  final BoxConstraints constraints;
  final Widget Function(int index, int totalCount) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    final aspectRatio = width / height;

    int columns;

    if (aspectRatio < 0.8) {
      columns = 1;
    } else if (aspectRatio < 1.4) {
      columns = 2;
    } else {
      columns = 3;
    }

    // The gap is also kept around the block.
    final side = math.max(
      0.0,
      math.min(
        (width - (columns + 1) * _spacing) / columns,
        (height - (_rows + 1) * _spacing) / _rows,
      ),
    );
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: _spacing,
        children: [
          for (var row = 0; row < _rows; row++)
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: _spacing,
              children: [
                for (var column = 0; column < columns; column++)
                  SizedBox.square(
                    dimension: side,
                    child: itemBuilder(row * columns + column, _rows * columns),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _QrImagePainter extends CustomPainter {
  const _QrImagePainter(this.image);

  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(_QrImagePainter old) => !identical(old.image, image);
}
