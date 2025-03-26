import 'dart:async';
import 'dart:developer';
import 'dart:ffi';
import 'dart:io';

import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/features/qr_page.dart';
import 'package:blast_qr/file_badge_count.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blast_qr/model/receiving_file_metadata.dart';
import 'package:blast_qr/widgets/bottom_sheets.dart';
import 'package:blast_qr/widgets/logo_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:blast_qr/model/blast_qrcode_data.dart';
import 'package:blast_qr/raptorq/raptorq_decoder.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  static const speedPollingMs = 200;

  Timer? _speedTimer;
  late RaptorqDecoder _decoder;

  bool _shouldScan = true;
  bool _loadingResult = false;
  String _infoString = '';
  double _progress = 0;
  double _speed = 0;
  int _decodedChunkCount = 0;
  int _dataLengthInLastPeriod = 0;
  bool _showsReaderWidget = true;
  bool _hapticFeedback = true;
  bool _transferComplete = false;
  ReceivingFileMetadata? _fileMetadata;

  @override
  void initState() {
    super.initState();
    _createDecoder();
  }

  @override
  void dispose() {
    _speedTimer?.cancel();
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
            onPressed: () async {
              setState(() {
                _hapticFeedback = !_hapticFeedback;
              });
            },
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedSmartPhone03,
              color:
                  _hapticFeedback
                      ? context.color.onSurface
                      : context.color.outline,
            ),
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
          ScanProgressWidget(
            info: _infoString,
            progress: _progress,
            fileExtension: _fileMetadata?.extension ?? '',
            complete: _transferComplete,
            onTapCancel: _reset,
          ),
          // Speed bar
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 80,
            ),
            child: AnimatedContainer(
              duration: 300.milliseconds,
              curve: Curves.easeInOut,
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

  void _startSpeedTimer() {
    _speedTimer = Timer.periodic(const Duration(milliseconds: speedPollingMs), (
      _,
    ) {
      _speed = _dataLengthInLastPeriod / speedPollingMs;
      _dataLengthInLastPeriod = 0;
      setState(() {
        _infoString = '$_decodedChunkCount | ${_speed.toStringAsFixed(1)}kB/s';
      });
    });
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
      _decoder.decodeChunk(blastQr.data, blastQr.transferLength, blastQr.mtu);
      if (_fileMetadata == null) {
        _fileMetadata = ReceivingFileMetadata(
          extension: blastQr.fileExtension,
          size: blastQr.transferLength,
          isCompressed: blastQr.isCompressedData,
        );
        debugPrint('Scanning file with: ${_fileMetadata.toString()}');
      }
    } else {
      _handleRegularQRCodeResult(result.text);
    }
  }

  void _handleDecodeProgress(int chunkLen, int chunkCount, double progress) {
    setState(() {
      _progress = progress;
      _dataLengthInLastPeriod += chunkLen;
      _decodedChunkCount = chunkCount;
      _infoString = '$_decodedChunkCount | ${_speed.toStringAsFixed(1)}kB/s';
    });

    if (_hapticFeedback) {
      HapticFeedback.lightImpact();
    }

    if (_speedTimer?.isActive == false || _speedTimer == null) {
      _startSpeedTimer();
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
    _speed = 0;
    _dataLengthInLastPeriod = 0;
    _decodedChunkCount = 0;
    _shouldScan = false;
    _loadingResult = true;
    _speedTimer?.cancel();
    _transferComplete = true;
    setState(() {});
  }

  void _handleResult(Uint8List data) async {
    if (_fileMetadata == null) {
      return;
    }
    _loadingResult = false;

    setState(() {
      _infoString = '';
    });

    final directory = await getApplicationDocumentsDirectory();
    final itemsDirectory = Directory('${directory.path}/docs');

    if (await itemsDirectory.exists() == false) {
      await itemsDirectory.create();
    }

    var bytes = data;
    if (_fileMetadata!.isCompressed) {
      debugPrint('Decompressing data');
      bytes = gzip.decode(data) as Uint8List;
    }

    String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final resultFile = await File(
      '${itemsDirectory.path}/$timestamp.${_fileMetadata!.extension}',
    ).writeAsBytes(bytes);
    final fileWrapper = await resultFile.toFileWrapper();
    final timeInSeconds = _decoder.elapsedTime / 1000;

    if (!mounted) {
      return;
    }

    // Increment file badge
    Provider.of<FileBadgeCount>(context, listen: false).add();

    HapticFeedback.heavyImpact();

    _showResultSheet(fileWrapper, timeInSeconds).then((_) {
      _reset();
    });
  }

  Future<void> _showResultSheet(FileWrapper file, double timeInSeconds) async {
    return showSheet(
      context: context,
      title: '${context.l10n.received_in} ${timeInSeconds.toStringAsFixed(1)}s',
      body: Column(
        spacing: 8,
        children: [
          GestureDetector(
            onTap: () {
              _onTapOpen(file);
            },
            child: Container(
              width: 150,
              height: 150,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(60),
                    spreadRadius: 0,
                    blurRadius: 1,
                    offset: Offset(0, 2),
                  ),
                ],
                borderRadius: BorderRadius.circular(12),
              ),
              child: file.buildThumbnail(context, showsAvifThumbnail: true),
            ),
          ),
          Text(file.name),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              spacing: 8,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      Provider.of<FileBadgeCount>(
                        context,
                        listen: false,
                      ).subtract();
                      await file.file.delete();
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text(context.l10n.discard),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(context.l10n.save),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
    _speedTimer?.cancel();
    _shouldScan = false;
    _decoder.reset();
    _loadingResult = false;
    _infoString = '';
    _progress = 0;
    _speed = 0;
    _decodedChunkCount = 0;
    _transferComplete = false;
    _fileMetadata = null;
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
    await Future.delayed(const Duration(milliseconds: 10));
    if (mounted) {
      setState(() {
        _showsReaderWidget = true;
      });
    }
  }

  void _onTapOpen(FileWrapper file) async {
    try {
      OpenFile.open(file.file.path, type: file.type.mimeType ?? '');
    } catch (error) {
      Navigator.of(context).pop();
      final snackBar = SnackBar(content: Text(error.toString()));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }
}

class ScanProgressWidget extends StatelessWidget {
  const ScanProgressWidget({
    super.key,
    required this.progress,
    required this.fileExtension,
    required this.info,
    required this.complete,
    required this.onTapCancel,
  });

  final double progress;
  final String fileExtension;
  final String info;
  final bool complete;
  final void Function() onTapCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          child: Container(
                height: 84,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.zero,
                    bottomRight: Radius.zero,
                  ),
                  color: context.color.surface,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 16, 24),
                  child: Row(
                    spacing: 8,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(
                              value: progress > 1 ? null : progress,
                              color: Colors.green,
                              backgroundColor: context.color.outline,
                            ),
                          ),
                          if (!complete) ...[
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey,
                              ),
                              width: 44,
                              height: 44,
                            ),
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedQrCode,
                              size: 32,
                              color: Colors.white.withAlpha(60),
                            ),
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    fileExtension.toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (complete) ...[
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green,
                              ),
                              width: 36,
                              height: 36,
                            ),
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedTick01,
                              size: 24,
                              color: Colors.white,
                            ),
                          ],
                        ],
                      ),
                      if (complete)
                        Expanded(
                          child: Text(
                            context.l10n.done,
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: 'Jersey25',
                              color: context.color.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      if (!complete && progress > 1) ...[
                        Expanded(
                          child: FittedBox(
                            alignment: Alignment.centerLeft,
                            fit: BoxFit.scaleDown,
                            child: Text(
                              context.l10n.keep_scanning_msg,
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: 'Jersey25',
                                color: context.color.onSurface,
                              ),
                              maxLines: 1,
                              textAlign: TextAlign.start,
                            ),
                          ),
                        ),
                      ],
                      if (!complete) ...[
                        Text(
                          info,
                          style: TextStyle(color: context.color.onSurface),
                          textAlign: TextAlign.end,
                        ),
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: IconButton(
                            onPressed: onTapCancel,
                            style: IconButton.styleFrom(
                              backgroundColor: context.color.primaryContainer,
                              foregroundColor: context.color.onSurface,
                            ),
                            padding: EdgeInsets.zero,
                            icon: Icon(Icons.clear, size: 16),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )
              .animate(target: info.isNotEmpty ? 1 : 0)
              .fade()
              .slideY(
                begin: 0.75,
                end: 0,
                duration: 300.ms,
                curve: Curves.easeOutBack,
              ),
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom - 12 - 16),
      ],
    );
  }
}
