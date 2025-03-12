import 'dart:developer';
import 'dart:io';

import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/file_badge_count.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blast_qr/widgets/bottom_sheets.dart';
import 'package:blast_qr/widgets/logo_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:blast_qr/model/blast_qrcode_data.dart';
import 'package:blast_qr/raptorq/raptorq_decoder.dart';
import 'package:blast_qr/features/preview_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
  String _fileExt = '';
  double _progress = 0;
  double _speed = 0;
  bool _showsReaderWidget = true;
  bool _hapticFeedback = true;

  @override
  void initState() {
    super.initState();
    _createDecoder();
  }

  @override
  void dispose() {
    _decoder.reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: LogoWidget(),
        centerTitle: true,
        toolbarHeight: 80,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _hapticFeedback = !_hapticFeedback;
              });
            },
            icon: Icon(Icons.vibration, color: context.color.onSurface),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          GestureDetector(
            onTap: () {
              // Temporary fix for: https://github.com/flutter/flutter/issues/152763
              _resetReaderWidget();
            },
            child:
                _showsReaderWidget
                    ? ReaderWidget(
                      scanDelay: Duration.zero,
                      scanDelaySuccess: Duration.zero,
                      codeFormat: Format.qrCode,
                      cropPercent: 1.0,
                      showGallery: false,
                      showToggleCamera: false,
                      showFlashlight: false,
                      onScan: _handleScan,
                    )
                    : SizedBox(),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                child: Container(
                      height: 68,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: context.color.surface,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
                        child: Row(
                          spacing: 8,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: CircularProgressIndicator(
                                    value: _progress > 1 ? null : _progress,
                                    color: Colors.green,
                                    backgroundColor: context.color.surface,
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey,
                                  ),
                                  width: 44,
                                  height: 44,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        _fileExt.toUpperCase(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.description,
                                  size: 32,
                                  color: Colors.white.withAlpha(80),
                                ),
                              ],
                            ),
                            if (_progress > 1) ...[
                              Spacer(),
                              SizedBox(
                                width: 100,
                                child: FittedBox(
                                  child: Text(
                                    context.l10n.keep_scanning_msg,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontFamily: 'Jersey25',
                                      color: context.color.onSurface,
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ),
                            ],
                            Spacer(),
                            Text(
                              _infoString,
                              style: TextStyle(color: context.color.onSurface),
                              textAlign: TextAlign.end,
                            ),
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: IconButton(
                                onPressed: _reset,
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      context.color.primaryContainer,
                                  foregroundColor: context.color.onSurface,
                                ),
                                padding: EdgeInsets.zero,
                                icon: Icon(Icons.clear, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .animate(target: _infoString.isNotEmpty ? 1 : 0)
                    .fade()
                    .slideY(
                      begin: 1,
                      end: 0,
                      duration: 300.ms,
                      curve: Curves.easeOutBack,
                    ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom - 6),
            ],
          ),
          // Speed bar
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 80,
            ),
            child: Container(
              height: 3,
              width: MediaQuery.of(context).size.width * (_speed / 20),
              color: context.color.primary,
            ),
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
      onReceiveResult: _handleResult,
      onTransferComplete: _handleTransferComplete,
      onProcessChunk: _handleDecodeProgress,
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

    if (BlastQrcodeData.bytesIsValidBlastQrCode(result.rawBytes)) {
      final blastQr = _parseQrCode(result)!;
      _fileExt = blastQr.fileExtension;
      _decoder.decodeChunk(blastQr.data, blastQr.transferLength, blastQr.mtu);
    } else {
      _handleRegularQRCodeResult(result.text);
    }
  }

  void _handleDecodeProgress(int chunkCount, double speed, double progress) {
    setState(() {
      _progress = progress;
      _speed = speed;
      _infoString = '$chunkCount | ${speed.toStringAsFixed(1)}';
    });

    if (_hapticFeedback) {
      HapticFeedback.lightImpact();
    }
  }

  BlastQrcodeData? _parseQrCode(Code result) {
    if (result.rawBytes == null) {
      log("null bytes");
      return null;
    }
    try {
      final data = BlastQrcodeData.fromBytes(result.rawBytes!);
      return data;
    } catch (error) {
      log(error.toString());
      return null;
    }
  }

  void _handleTransferComplete() {
    _progress = 1;
    _shouldScan = false;
    _loadingResult = true;
    _infoString = '';
    setState(() {});
  }

  void _handleResult(Uint8List data) async {
    _loadingResult = false;
    HapticFeedback.heavyImpact();

    final directory = await getApplicationDocumentsDirectory();
    final itemsDirectory = Directory('${directory.path}/docs');

    if (await itemsDirectory.exists() == false) {
      await itemsDirectory.create();
    }

    String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final resultFile = await File(
      '${itemsDirectory.path}/$timestamp.$_fileExt',
    ).writeAsBytes(data);
    final fileWrapper = await resultFile.toFileWrapper();
    final timeInSeconds = _decoder.elapsedTime / 1000;

    if (!mounted) {
      return;
    }

    // Increment file badge
    Provider.of<FileBadgeCount>(context, listen: false).add();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
          bottom: Radius.zero,
        ),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom:
                MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).viewPadding.bottom,
          ),
          child: PreviewPage(
            file: fileWrapper,
            time: '${timeInSeconds.toStringAsFixed(1)}s',
          ),
        );
      },
    ).then((_) {
      _reset();
    });
  }

  void _handleRegularQRCodeResult(String? text) async {
    _shouldScan = false;
    HapticFeedback.heavyImpact();

    showMessage(
      context: context,
      title: context.l10n.result,
      message: text ?? '',
      confirmTitle: context.l10n.copy,
      secondaryTitle: context.l10n.dismiss,
      onConfirmTap: () {
        if (text != null) {
          Clipboard.setData(ClipboardData(text: text));
        }
      },
    ).then((_) {
      _reset();
    });
  }

  void _reset() async {
    _shouldScan = false;
    _decoder.reset();
    _loadingResult = false;
    _infoString = '';
    _progress = 0;
    _speed = 0;
    setState(() {});

    // Wait a second to start scanning again
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _shouldScan = true;
      });
    }
  }

  // Temporary fix for: https://github.com/flutter/flutter/issues/152763
  void _resetReaderWidget() async {
    setState(() {
      _showsReaderWidget = false;
    });
    await Future.delayed(const Duration(milliseconds: 30));
    if (mounted) {
      setState(() {
        _showsReaderWidget = true;
      });
    }
  }
}
