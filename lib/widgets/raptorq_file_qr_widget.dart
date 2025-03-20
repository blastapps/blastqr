import 'dart:async';
import 'dart:io';

import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class RaptorQrWidgetController with ChangeNotifier {
  Timer? _timer;

  int currentChunkIndex = 0;
  int _length = 0;

  void start(Duration delay, int length) {
    _length = length;
    _timer = Timer.periodic(delay, _nextChunk);
  }

  void stopAnimation() {
    _timer?.cancel();
  }

  void _nextChunk(_) {
    currentChunkIndex += 1;
    if (currentChunkIndex >= _length) {
      currentChunkIndex = 0;
    }
    notifyListeners();
  }
}

class RaptorQrWidget extends StatefulWidget {
  final RaptorQrWidgetController controller;
  final FileWrapper file;
  final int mtu;

  const RaptorQrWidget({
    super.key,
    required this.file,
    required this.mtu,
    required this.controller,
  });

  @override
  State<RaptorQrWidget> createState() => _RaptorQrWidgetState();
}

class _RaptorQrWidgetState extends State<RaptorQrWidget> {
  static const List<int> defaultFpeses = [15, 16, 20, 22, 25, 30];

  List<QrCode> _qrCodes = [];
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
  void didUpdateWidget(covariant RaptorQrWidget oldWidget) {
    if (oldWidget.file != widget.file) {
      init();
    }
    super.didUpdateWidget(oldWidget);
  }

  void init() async {
    widget.controller.stopAnimation();
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
    widget.controller.stopAnimation();
    widget.controller.start(delay, _qrCodes.length);
  }

  @override
  void dispose() {
    widget.controller.stopAnimation();
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
            Text(
              context.l10n.generating_codes,
              style: TextStyle(color: Colors.black),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(8),
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, child) {
          final index = widget.controller.currentChunkIndex;
          return Column(
            children: [
              FittedBox(
                child: QrImageView.withQr(
                  qr: _qrCodes[index],
                  version: QrVersions.auto,
                  size: _qrCodeWidth,
                ),
              ),
              SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${index + 1}/${_qrCodes.length}',
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

    _initTimer(Duration(milliseconds: (1000 / _fps).toInt()));
  }
}
