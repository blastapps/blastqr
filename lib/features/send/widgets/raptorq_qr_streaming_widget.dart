import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:blast_qr/features/send/helpers/file_qr_encoder.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blast_qr/model/image_compression_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Decides which frame each QR code shows, based on elapsed time.
///
/// In multi-code mode the codes don't all change at once: code `j` of `n`
/// changes `j/n` of a frame interval after code 0. A camera exposure that
/// catches the screen mid-change then loses at most one code instead of all
/// of them. Each code still changes at the playback fps.
class RaptorQrStreamingWidgetController with ChangeNotifier {
  /// Notify at this many steps per frame interval. Divisible by every grid
  /// size (1, 2, 4, 6), so each code's change time lands on a step.
  static const int _stepsPerFrame = 12;

  int _fps = 20;

  /// Time since playback started, and the point the current fps applies from.
  Duration _elapsed = Duration.zero;
  Duration _fpsOrigin = Duration.zero;

  /// Frames played before the last fps change.
  int _baseFrames = 0;
  int _lastStep = -1;

  /// How many times code [cell] of [cellCount] has changed.
  int framesAdvanced(int cell, int cellCount) {
    final frames = _framesSinceOrigin - cell / cellCount;
    return _baseFrames + math.max(0, frames.floor());
  }

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
    _lastStep = -1;
  }

  /// Changes fps without jumping: frames already played are kept. The next
  /// tick repaints.
  void setFps(int fps) {
    _baseFrames = framesAdvanced(0, 1);
    _fpsOrigin = _elapsed;
    _fps = fps;
    _lastStep = -1;
  }

  /// Called on every screen refresh by the widget's ticker. Time-based, so
  /// a pause (app in background) skips ahead instead of bursting frames.
  void tick(Duration elapsed) {
    if (_stopped) return;
    _elapsed = elapsed;
    final step = (_framesSinceOrigin * _stepsPerFrame).floor();
    if (step != _lastStep) {
      _lastStep = step;
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
  final bool fill;
  final Function()? onTap;
  final void Function(int)? onStart;

  const RaptorQrStreamingWidget({
    super.key,
    required this.file,
    required this.mtu,
    required this.fps,
    required this.controller,
    required this.imageCompressionSettings,
    this.fill = true,
    this.onTap,
    this.onStart,
  });

  @override
  State<RaptorQrStreamingWidget> createState() =>
      _RaptorQrStreamingWidgetState();
}

class _RaptorQrStreamingWidgetState extends State<RaptorQrStreamingWidget>
    with SingleTickerProviderStateMixin {
  static const List<int> _hardcodedFpses = [15, 16, 20, 22, 25, 30];

  late int _fps;
  late int _fpsIndex;
  late List<int> _fpsList;
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

  /// What each grid cell shows, and how many times the controller has told
  /// it to change.
  final List<ui.Image?> _cellImages = [];
  final List<int?> _cellSeqs = [];
  final List<int> _cellAdvanced = [];

  /// Number of cells in the last layout (1 when not in fill mode).
  int _cellCount = 1;

  List<int> _buildFpsList(int settingsFps) {
    final list = [..._hardcodedFpses];
    if (!list.contains(settingsFps)) {
      list.add(settingsFps);
      list.sort();
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _fpsList = _buildFpsList(widget.fps);
    _fps = widget.fps;
    _fpsIndex = _fpsList.indexOf(_fps);
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
      _fpsList = _buildFpsList(widget.fps);
      _fps = widget.fps;
      _fpsIndex = _fpsList.indexOf(_fps);
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
      final advanced = widget.controller.framesAdvanced(cell, _cellCount);
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
              itemBuilder: (gridIndex, totalCount, w, h) {
                // Read by the next tick; cells are filled from there.
                _cellCount = totalCount;
                final img =
                    gridIndex < _cellImages.length
                        ? _cellImages[gridIndex]
                        : null;
                return Container(
                  padding: const EdgeInsets.all(8),
                  height: w,
                  width: h,
                  // Own layer per code: a change repaints only that code.
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: img != null ? _QrImagePainter(img) : null,
                    ),
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
                    GestureDetector(
                      onTap: _cycleNextFps,
                      child: Text(
                        '${_fps}FPS',
                        style: const TextStyle(color: Colors.black),
                      ),
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

  void _cycleNextFps() {
    _fpsIndex = (_fpsIndex + 1) % _fpsList.length;
    setState(() {
      _fps = _fpsList[_fpsIndex];
    });
    _applyFps();
  }
}

class _FlexibleGrid extends StatelessWidget {
  const _FlexibleGrid({required this.constraints, required this.itemBuilder});

  final BoxConstraints constraints;
  final Widget Function(int index, int totalCount, double w, double h)
  itemBuilder;

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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(2, (rowIndex) {
        return Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(columns, (colIndex) {
              final index = rowIndex * columns + colIndex;
              return Expanded(
                child: Center(
                  child: itemBuilder(
                    index,
                    2 * columns,
                    width / columns,
                    height / 2,
                  ),
                ),
              );
            }),
          ),
        );
      }),
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
