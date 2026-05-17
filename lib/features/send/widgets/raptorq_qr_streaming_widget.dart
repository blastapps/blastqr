import 'dart:async';
import 'dart:ui' as ui;

import 'package:blast_qr/features/send/helpers/file_qr_encoder.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blast_qr/model/image_compression_settings.dart';
import 'package:flutter/material.dart';

class RaptorQrStreamingWidgetController with ChangeNotifier {
  Timer? _timer;

  int currentChunkIndex = 0;
  int _length = 0;

  void start(Duration delay) {
    _timer = Timer.periodic(delay, _nextChunk);
  }

  void stopAnimation() {
    _timer?.cancel();
  }

  void _nextChunk(_) {
    currentChunkIndex += 1;
    if (currentChunkIndex >= _length) {
      currentChunkIndex = 0;
      debugPrint('!!! Reached end of buffer');
    }
    notifyListeners();
  }

  void setLength(int length) {
    _length = length;
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

class _RaptorQrStreamingWidgetState extends State<RaptorQrStreamingWidget> {
  static const List<int> _hardcodedFpses = [15, 16, 20, 22, 25, 30];

  int _qrCount = 0;
  final Map<int, ui.Image> _imageCache = {};
  bool _isEncoding = true;
  late int _fps;
  late int _fpsIndex;
  late List<int> _fpsList;
  late StreamSubscription _imageStream;

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
    init();
  }

  @override
  void didUpdateWidget(covariant RaptorQrStreamingWidget oldWidget) {
    if (oldWidget.file != widget.file) {
      init();
    }
    if (oldWidget.fps != widget.fps) {
      _fpsList = _buildFpsList(widget.fps);
      _fps = widget.fps;
      _fpsIndex = _fpsList.indexOf(_fps);
      _initTimer();
    }
    super.didUpdateWidget(oldWidget);
  }

  void init() async {
    widget.controller.stopAnimation();
    _qrCount = 0;
    for (final img in _imageCache.values) {
      img.dispose();
    }
    _imageCache.clear();
    _isEncoding = true;

    debugPrint('Generating QR codes..');

    _imageStream = FileQrEncoder.encode(
      widget.file,
      widget.mtu,
      icSettings: widget.imageCompressionSettings,
      onCompressedSize: widget.onStart,
    ).listen((pixelData) {
      final index = _qrCount;
      _qrCount++;
      _generateUiImage(index, pixelData);
      widget.controller.setLength(_qrCount);
      if (_qrCount == 1) {
        _isEncoding = false;
        _initTimer();
        setState(() {});
      }
    });

    _imageStream.onDone(() {});
  }

  void _initTimer() {
    final delay = Duration(milliseconds: (1000 / _fps).toInt());
    widget.controller.stopAnimation();
    widget.controller.start(delay);
  }

  @override
  void dispose() {
    widget.controller.stopAnimation();
    _imageStream.cancel();
    for (final img in _imageCache.values) {
      img.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isEncoding || _qrCount == 0) {
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
          return ListenableBuilder(
            listenable: widget.controller,
            builder: (context, child) {
              final index = widget.controller.currentChunkIndex;
              final uiImage = _imageCache[index];
              final double adaptedPadding = widget.fill ? 8 : 16;

              if (widget.fill) {
                return _FlexibleGrid(
                  constraints: c,
                  itemBuilder: (gridIndex, totalCount, w, h) {
                    final step = _qrCount ~/ totalCount;
                    final imgIndex = (index + gridIndex * step) % _qrCount;
                    final img = _imageCache[imgIndex];
                    return Container(
                      padding: const EdgeInsets.all(8),
                      height: w,
                      width: h,
                      child: CustomPaint(
                        painter: img != null ? _QrImagePainter(img) : null,
                      ),
                    );
                  },
                );
              }

              return Column(
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(16, adaptedPadding, 16, 0),
                    height: qrSize - vOffset,
                    width: qrSize - hOffset,
                    child: CustomPaint(
                      painter:
                          uiImage != null ? _QrImagePainter(uiImage) : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${index + 1}/$_qrCount',
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
    _initTimer();
  }

  void _generateUiImage(int index, QrPixelData pixelData) {
    ui.decodeImageFromPixels(
      pixelData.pixels,
      pixelData.moduleCount,
      pixelData.moduleCount,
      ui.PixelFormat.rgba8888,
      (image) {
        if (mounted) {
          _imageCache[index] = image;
        } else {
          image.dispose();
        }
      },
    );
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
