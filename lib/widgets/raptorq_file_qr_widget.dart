import 'dart:async';
import 'dart:io';

import 'package:blast_qr/model/file_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class RaptorFileQrWidget extends StatefulWidget {
  final FileWrapper file;
  final int mtu;

  const RaptorFileQrWidget({super.key, required this.file, required this.mtu});

  @override
  State<RaptorFileQrWidget> createState() => _RaptorFileQrWidgetState();
}

class _RaptorFileQrWidgetState extends State<RaptorFileQrWidget> {
  Timer? _timer;

  static const List<int> defaultFpeses = [15, 16, 20, 22, 25, 30];

  List<QrCode> _qrCodes = [];
  int _currentIndex = 0;
  bool _isEncoding = true;
  int _fps = defaultFpeses[2];
  int _fpsIndex = 2;
  double _qrCodeWidth = 360;
  double _qrCodePlatformOffset = 0;

  @override
  void initState() {
    init();
    super.initState();

    final mediaQuery =
        (context.getElementForInheritedWidgetOfExactType<MediaQuery>()!.widget
                as MediaQuery)
            .data;
    _qrCodePlatformOffset = Platform.isIOS ? 0 : 16;
    if (mediaQuery.size.height > mediaQuery.size.width) {
      _qrCodeWidth = mediaQuery.size.width - _qrCodePlatformOffset;
    } else {
      _qrCodeWidth = mediaQuery.size.height - 112 - 80 - 16 - 28;
    }
  }

  @override
  void didUpdateWidget(covariant RaptorFileQrWidget oldWidget) {
    if (oldWidget.file != widget.file) {
      init();
    }
    super.didUpdateWidget(oldWidget);
  }

  void init() async {
    _timer?.cancel();
    _currentIndex = 0;
    _qrCodes = [];
    _isEncoding = true;

    _qrCodes = await widget.file.toQrCodeList(mtu: widget.mtu);

    _initTimer(Duration(milliseconds: (1000 / _fps).toInt()));
    _isEncoding = false;

    if (mounted) {
      setState(() {});
    }
  }

  void _initTimer(Duration delay) {
    _timer?.cancel();
    _timer = Timer.periodic(delay, _nextChunk);
  }

  void _nextChunk(Timer t) {
    _currentIndex += 1;
    if (_currentIndex >= _qrCodes.length) {
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
        width: double.infinity,
        height: _qrCodeWidth + 24 + _qrCodePlatformOffset,
        child: Column(
          spacing: 8,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator.adaptive(backgroundColor: Colors.black),
            Text('Generating codes...', style: TextStyle(color: Colors.black)),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          FittedBox(
            child: QrImageView.withQr(
              qr: _qrCodes[_currentIndex],
              version: QrVersions.auto,
              size: _qrCodeWidth,
            ),
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_currentIndex + 1}/${_qrCodes.length}',
                style: TextStyle(color: Colors.black),
              ),
              GestureDetector(
                onTap: () {
                  _setNextFps();
                },
                child: Text(
                  '${_fps}FPS',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
        ],
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

    _initTimer(Duration(milliseconds: (1000 / _fps).toInt()));
  }
}
