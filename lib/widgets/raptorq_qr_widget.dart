import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:base45/base45.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:blast_qr/model/blast_qrcode_data.dart';

class RaptorQrWidget extends StatefulWidget {
  final List<Uint8List> data;
  final Duration delay;
  final int transferLength;
  final QrEncodingType encodingType;

  const RaptorQrWidget({
    super.key,
    required this.data,
    required this.delay,
    this.encodingType = QrEncodingType.base64,
    required this.transferLength,
  });

  @override
  State<RaptorQrWidget> createState() => _RaptorQrWidgetState();
}

class _RaptorQrWidgetState extends State<RaptorQrWidget> {
  Timer? _timer;

  List<String> _encodedStrings = [];
  int _currentIndex = 0;
  bool _isEncoding = true;

  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant RaptorQrWidget oldWidget) {
    if (oldWidget.data != widget.data) {
      init();
    }
    if (oldWidget.delay != widget.delay) {
      _initTimer();
    }
    super.didUpdateWidget(oldWidget);
  }

  void init() {
    _timer?.cancel();
    _currentIndex = 0;
    _encodedStrings = [];
    _isEncoding = true;

    _encodeAsString().then((_) {
      _initTimer();
      _isEncoding = false;
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _initTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.delay, _nextChunk);
  }

  Future<void> _encodeAsString() async {
    final type = widget.encodingType;
    final encodeMethod =
        type == QrEncodingType.base64 ? base64Encode : Base45.encode;
    log('Encoding with ${widget.encodingType.name}');
    final len = widget.transferLength;
    _encodedStrings =
        widget.data
            .map((c) => '$len/${type.index}|${encodeMethod(c)}')
            .toList();

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
        QrImageView(
          data: _encodedStrings[_currentIndex],
          version: QrVersions.auto,
          size: 360,
          gapless: false,
        ),
        Text('${_currentIndex + 1}/${widget.data.length}'),
      ],
    );
  }
}
