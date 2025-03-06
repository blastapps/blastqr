import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:blast_qr/model/blast_qrcode_data.dart';
import 'package:blast_qr/raptorq/raptorq_decoder.dart';
import 'package:blast_qr/features/preview_page.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  late RaptorqDecoder _decoder;
  bool _shouldScan = true;
  bool _loadingResult = false;
  String _infoString = '';

  @override
  void initState() {
    super.initState();
    _createDecoder();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ReaderWidget(
            scanDelay: Duration.zero,
            scanDelaySuccess: Duration.zero,
            resolution: ResolutionPreset.low,
            codeFormat: Format.qrCode,
            cropPercent: 1.0,
            showGallery: false,
            showToggleCamera: false,
            showFlashlight: false,
            onScan: _handleScan,
          ),
          if (_infoString.isNotEmpty)
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.black.withAlpha(80),
                  ),
                  child: Text(
                    _infoString,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(height: 56),
              ],
            ),
          if (_loadingResult)
            Center(
              child: Container(
                width: 80,
                height: 80,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: CircularProgressIndicator.adaptive(),
              ),
            ),
        ],
      ),
    );
  }

  void _createDecoder() {
    _decoder = RaptorqDecoder(
      mtu: 924,
      onReceiveResult: _handleResult,
      onTransferComplete: _handleTransferComplete,
      onProcessChunk: _handleProgress,
    );
  }

  void _handleScan(Code result) {
    if (!_shouldScan) {
      return;
    }
    log('Found code');

    if (_decoder.complete) {
      _shouldScan = false;
      return;
    }

    final blastQr = _parseQrCode(result);
    if (blastQr != null) {
      _decoder.decodeChunk(blastQr.data, blastQr.transferLength);
    }
  }

  void _handleTransferComplete() {
    _shouldScan = false;
    _loadingResult = true;
    setState(() {});
  }

  void _handleResult(Uint8List data) {
    _loadingResult = false;
    HapticFeedback.heavyImpact();
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder:
                (context) => PreviewPage(
                  data: data,
                  time: '${_decoder.elapsedTime / 1000}s',
                ),
          ),
        )
        .then((_) {
          _decoder.reset();
          _shouldScan = true;
          _loadingResult = false;
          _infoString = '';
          setState(() {});
        });
  }

  void _handleProgress(int chunkCount, String speed) {
    setState(() {
      _infoString = '$chunkCount | $speed';
    });
  }

  BlastQrcodeData? _parseQrCode(Code result) {
    if (result.rawBytes == null) {
      log("null bytes");
      return null;
    }
    return BlastQrcodeData.fromBytes(result.rawBytes!);
  }
}
