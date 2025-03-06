import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:blast_qr/raptorq/raptorq_encoder.dart';

class RaptorFileQrWidget extends StatefulWidget {
  final File file;

  const RaptorFileQrWidget({super.key, required this.file});

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
  int _transferLength = 0;
  List<Uint8List> _data = [];
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
    _qrCodeWidth = mediaQuery.size.width - _qrCodePlatformOffset;
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

    log('Encoding file...');
    _data = await _encodeFile();

    log('Generating ${_data.length} QR codes...');
    await _generateQrCodes();

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

  Future<List<Uint8List>> _encodeFile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final bytes = await widget.file.readAsBytes();
    final fileSize = bytes.lengthInBytes;
    final repairPackets = fileSize < 1000000 ? fileSize / 10000 * 2 : 50;

    log('Encoding with MTU: 924, repairPacketsPerBlock: $repairPackets');
    final encoder = RaptorqEncoder(
      mtu: 924,
      repairPacketsPerBlock: repairPackets.toInt(),
    );
    final encodedData = await encoder.encode(bytes);

    _transferLength = bytes.length;
    log('Chunk size: ${encodedData.first.length}');
    setState(() {});

    return encodedData;
  }

  Future<void> _generateQrCodes() async {
    final len = _transferLength;
    _qrCodes =
        _data.map((c) {
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
    if (_currentIndex >= _data.length) {
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
              padding: EdgeInsets.all(8),
              size: _qrCodeWidth,
              gapless: false,
            ),
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_currentIndex + 1}/${_data.length}',
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
