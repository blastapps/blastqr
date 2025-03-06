import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class RaptorByteQrWidget extends StatefulWidget {
  final List<Uint8List> data;
  final int transferLength;

  const RaptorByteQrWidget({
    super.key,
    required this.data,
    required this.transferLength,
  });

  @override
  State<RaptorByteQrWidget> createState() => _RaptorByteQrWidgetState();
}

class _RaptorByteQrWidgetState extends State<RaptorByteQrWidget> {
  Timer? _timer;

  static const List<int> defaultFpeses = [15, 16, 20, 22, 25, 30];

  List<QrCode> _qrCodes = [];
  int _currentIndex = 0;
  bool _isEncoding = true;
  int _fps = defaultFpeses[2];
  int _fpsIndex = 2;

  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant RaptorByteQrWidget oldWidget) {
    if (oldWidget.data != widget.data) {
      init();
    }
    super.didUpdateWidget(oldWidget);
  }

  void init() {
    _timer?.cancel();
    _currentIndex = 0;
    _qrCodes = [];
    _isEncoding = true;

    _generateQrCodes().then((_) {
      _initTimer(Duration(milliseconds: (1000 / _fps).toInt()));
      _isEncoding = false;
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _initTimer(Duration delay) {
    _timer?.cancel();
    _timer = Timer.periodic(delay, _nextChunk);
  }

  Future<void> _generateQrCodes() async {
    final len = widget.transferLength;
    _qrCodes =
        widget.data.map((c) {
          Uint8List sizeBytes = Uint8List(8)
            ..buffer.asByteData().setUint64(0, len, Endian.big);

          Uint8List combined = Uint8List(8 + c.length);

          combined.setAll(0, sizeBytes); // Copy metadata
          combined.setAll(8, c); // Copy file data

          return QrCode.fromUint8List(
            data: combined,
            errorCorrectLevel: QrErrorCorrectLevel.L,
          );
        }).toList();
    await Future.delayed(const Duration(milliseconds: 400));
  }

  void _nextChunk(Timer t) {
    _currentIndex += 1;
    if (_currentIndex >= widget.data.length) {
      _currentIndex = 0;
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isEncoding) {
      return SizedBox(
        width: 390,
        height: 390,
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    return Column(
      children: [
        QrImageView.withQr(
          qr: _qrCodes[_currentIndex],
          version: QrVersions.auto,
          size: 355,
          gapless: false,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 8, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_currentIndex + 1}/${widget.data.length}'),
              GestureDetector(
                onTap: () {
                  _setNextFps();
                },
                child: Text('${_fps}FPS'),
              ),
            ],
          ),
        ),
      ],
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

    _initTimer(Duration(milliseconds: (1000 / _fps).toInt()));
  }
}
