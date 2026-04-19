import 'dart:async';

import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blast_qr/model/image_compression_settings.dart';
import 'package:blast_qr/qr_painter.dart';
import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

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
  final ImageCompressionSettings? imageCompressionSettings;
  final bool fill;
  final Function()? onTap;

  const RaptorQrStreamingWidget({
    super.key,
    required this.file,
    required this.mtu,
    required this.controller,
    required this.imageCompressionSettings,
    this.fill = true,
    this.onTap,
  });

  @override
  State<RaptorQrStreamingWidget> createState() =>
      _RaptorQrStreamingWidgetState();
}

class _RaptorQrStreamingWidgetState extends State<RaptorQrStreamingWidget> {
  static const List<int> defaultFpeses = [15, 16, 20, 22, 25, 30];

  List<QrImage> _qrImages = [];
  bool _isEncoding = true;
  bool _hasReceivedAllQrCodes = false;
  int _fps = defaultFpeses[2];
  int _fpsIndex = 2;
  int _frameTick = 0;
  late StreamSubscription _imageStream;

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void didUpdateWidget(covariant RaptorQrStreamingWidget oldWidget) {
    if (oldWidget.file != widget.file) {
      init();
    }
    super.didUpdateWidget(oldWidget);
  }

  void init() async {
    widget.controller.stopAnimation();
    _qrImages = [];
    _isEncoding = false;

    debugPrint('Generating QR codes..');

    _imageStream = widget.file
        .qrImageStream(widget.mtu, icSettings: widget.imageCompressionSettings)
        .listen((image) {
          _qrImages.add(image);
          widget.controller.setLength(_qrImages.length);
          if (_qrImages.length == 1) {
            _initTimer();
            setState(() {});
          }
        });

    _imageStream.onDone(() {
      setState(() {
        _hasReceivedAllQrCodes = true;
      });
    });
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isEncoding || _qrImages.isEmpty) {
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
      child: LayoutBuilder(
        builder: (context, c) {
          final qrSize = c.maxWidth > c.maxHeight ? c.maxHeight : c.maxWidth;
          final hOffset = c.maxWidth > (c.maxHeight - 20) ? 12 : 0;
          final vOffset = c.maxWidth > (c.maxHeight - 20) ? 20 : 8;
          return ListenableBuilder(
            listenable: widget.controller,
            builder: (context, child) {
              if (_hasReceivedAllQrCodes) {
                _frameTick = (_frameTick + 1) % _qrImages.length;
              }
              final incIndex = widget.controller.currentChunkIndex;
              final decIndex = _qrImages.length - 1 - _frameTick;
              final painter = QrPainter.withQr(qrImage: _qrImages[incIndex]);
              final painter2 = QrPainter.withQr(qrImage: _qrImages[decIndex]);
              final double adaptedPadding = widget.fill ? 8 : 16;
              if (widget.fill) {
                return _FlexibleGrid(
                  constraints: c,
                  itemBuilder: (index, w, h) {
                    return Container(
                      padding: const EdgeInsets.all(8),
                      height: w,
                      width: h,
                      child: CustomPaint(
                        painter: index % 2 == 0 ? painter : painter2,
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
                    child: CustomPaint(painter: painter),
                  ),
                  if (widget.fill)
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      height: qrSize - vOffset - 26,
                      width: qrSize - hOffset,
                      child: CustomPaint(painter: painter2),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$incIndex/${_qrImages.length}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _setNextFps();
                          },
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

  void _setNextFps() {
    if (_fpsIndex > defaultFpeses.length - 2) {
      _fpsIndex = 0;
    } else {
      _fpsIndex += 1;
    }
    setState(() {
      _fps = defaultFpeses[_fpsIndex];
    });
    _initTimer();
  }
}

class _FlexibleGrid extends StatelessWidget {
  const _FlexibleGrid({required this.constraints, required this.itemBuilder});

  final BoxConstraints constraints;
  final Widget Function(int index, double w, double h) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    final aspectRatio = width / height;

    // Decide number of columns
    int columns;

    if (aspectRatio < 0.8) {
      // Very tall (phone portrait)
      columns = 1;
    } else if (aspectRatio < 1.4) {
      // Square-ish
      columns = 2;
    } else {
      // Wide screen
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
                  child: itemBuilder(index, width / columns, height / 2),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}
