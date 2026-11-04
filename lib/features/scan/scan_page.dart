import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/crypto/transfer_crypto.dart';
import 'package:blast_qr/extensions/string_extension.dart';
import 'package:blast_qr/features/scan/decode_stats.dart';
import 'package:blast_qr/features/scan/received_file_writer.dart';
import 'package:blast_qr/features/scan/scan_camera.dart';
import 'package:blast_qr/features/scan/transfer_tracker.dart';
import 'package:blast_qr/features/scan/widgets/password_sheet.dart';
import 'package:blast_qr/features/scan/widgets/qr_scanner.dart';
import 'package:blast_qr/features/settings/settings_page.dart';
import 'package:blast_qr/file_badge_count.dart';
import 'package:blast_qr/file_name_utils.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/blast_qrcode_data.dart';
import 'package:blast_qr/model/file_extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blast_qr/model/receiving_file_metadata.dart';
import 'package:blast_qr/model/scanned_qr_code.dart';
import 'package:blast_qr/nav_bar_visibility.dart';
import 'package:blast_qr/platform_support.dart';
import 'package:blast_qr/raptorq/raptorq_decoder.dart';
import 'package:blast_qr/received_files_directory.dart';
import 'package:blast_qr/sound_feedback.dart';
import 'package:blast_qr/temp_files.dart';
import 'package:blast_qr/theme.dart';
import 'package:blast_qr/widgets/bottom_sheets.dart';
import 'package:blast_qr/widgets/circle_button.dart';
import 'package:blast_qr/widgets/file_preview.dart';
import 'package:blast_qr/widgets/logo_widget.dart';
import 'package:blast_qr/widgets/strike_painter.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  static const speedPollingMs = 200;

  final _renameController = TextEditingController();

  Timer? _speedTimer;
  late RaptorqDecoder _decoder;

  bool _shouldScan = true;
  bool _isReceivingData = false;
  bool _loadingResult = false;
  String _statusMessage = '';
  double _progress = 0;
  double _speed = 0;
  int _decodedChunkCount = 0;
  int _dataLengthInLastPeriod = 0;
  bool _showsReaderWidget = true;
  bool _cameraLoaded = false;
  bool _showLowSpeedWarning = false;
  DateTime? _lowSpeedStartTime;
  late SoundFeedbackService _soundService;
  late AppSettings _appSettings;
  DateTime _latestScanStartTime = DateTime.now();
  ReceivingFileMetadata? _fileMetadata;

  /// Decides which transfer the scanned frames belong to.
  final _tracker = TransferTracker();
  CameraController? _cameraController;
  bool _focusLocked = false;
  final _readerKey = GlobalKey<QrScannerState>();
  Offset? _focusIndicator;

  /// Quick taps in a row; the third restarts the camera.
  int _taps = 0;
  final _sinceLastTap = Stopwatch();

  @override
  void initState() {
    super.initState();
    _createDecoder();
    _soundService = SoundFeedbackService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _cameraLoaded = true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appSettings = Provider.of<AppSettings>(context, listen: true);
    _updateCameraLabel();
    _configureCamera();
  }

  /// The frame rate the open camera uses, which [QrScanner] picks when none
  /// is set.
  int? _openedFps;

  void _updateCameraLabel() {
    final fps = _openedFps ?? _cameraFps;
    DecodeStats.instance.camera = [
      _cameraResolution.name.capitalize(),
      if (fps == null)
        'default FPS'
      else
        '$fps FPS${_cameraFps == null ? ' (highest)' : ''}',
      '${_appSettings.cameraZoom}x zoom',
      if (Platform.isIOS) ...[
        _appSettings.debugVideoHdr ? 'HDR on' : 'HDR off',
        switch (_appSettings.debugExposureMs) {
          null => 'max ${ScanCamera.defaultMaxExposureMs} ms exposure',
          0 => 'no exposure limit',
          final ms => '$ms ms exposure',
        },
      ],
    ].join(', ');
  }

  @override
  void dispose() {
    _speedTimer?.cancel();
    _decoder.dispose();
    DecodeStats.instance.endTransfer();
    _soundService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = _appSettings;
    final darkColors = darkColorScheme(context.color.primary);
    return Theme(
      data: BlastTheme.dark.buildTheme(context.color.primary, false),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: context.useDesktopLayout ? null : const LogoWidget(),
          centerTitle: true,
          toolbarHeight: 80,
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          leadingWidth: 104,
          leading: Row(
            children: [
              CircleButton(
                padding: const EdgeInsetsDirectional.only(start: 8),
                onPressed: () {
                  appSettings.updateHapticFeedback(!appSettings.hapticFeedback);
                },
                icon: CustomPaint(
                  foregroundPainter: appSettings.hapticFeedback
                      ? null
                      : StrikePainter(
                          color: darkColors.onPrimaryContainer.withValues(
                            alpha: 0.5,
                          ),
                          gapColor: darkColors.primaryContainer,
                        ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedSmartPhone03,
                    color: appSettings.hapticFeedback
                        ? darkColors.onPrimaryContainer
                        : darkColors.onPrimaryContainer.withValues(alpha: 0.5),
                  ),
                ),
              ),
              CircleButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  appSettings.updateSoundFeedback(!appSettings.soundFeedback);
                },
                icon: HugeIcon(
                  icon: appSettings.soundFeedback
                      ? HugeIcons.strokeRoundedVolumeLow
                      : HugeIcons.strokeRoundedVolumeOff,
                  color: appSettings.soundFeedback
                      ? darkColors.onPrimaryContainer
                      : darkColors.onPrimaryContainer.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          actions: [
            if (!context.useDesktopLayout)
              CircleButton(
                onPressed: () async {
                  _setCameraOn(false);
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return const SettingsPage();
                      },
                    ),
                  );
                  _setCameraOn(true);
                },
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedSettings01),
              ),
          ],
        ),
        body: Stack(
          alignment: Alignment.topCenter,
          children: [
            GestureDetector(
              onTapUp: (details) => _onPreviewTap(details.localPosition),
              child: _showsReaderWidget && _cameraLoaded
                  // The scanner outlines codes in primaryColor, which a
                  // dark theme sets to the surface color.
                  ? Builder(
                      builder: (context) => Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(primaryColor: context.color.primary),
                        child: QrScanner(
                          key: _readerKey,
                          resolution: _cameraResolution,
                          fps: _cameraFps,
                          zoom: appSettings.cameraZoom,
                          autoRestart: _shouldScan,
                          onCodes: _handleMultiscan,
                          onCameraChanged: _onCameraChanged,
                          onFrame: DecodeStats.instance.record,
                        ),
                      ),
                    )
                  : const SizedBox(),
            ),
            if (_focusIndicator case final tap?)
              Positioned(
                left: tap.dx - 32,
                top: tap.dy - 32,
                child: IgnorePointer(
                  child:
                      Container(
                            key: ValueKey(tap),
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                          )
                          .animate(
                            onComplete: (_) {
                              if (mounted && _focusIndicator == tap) {
                                setState(() => _focusIndicator = null);
                              }
                            },
                          )
                          .scale(
                            begin: const Offset(1.4, 1.4),
                            duration: 200.ms,
                            curve: Curves.easeOut,
                          )
                          .then(delay: 600.ms)
                          .fadeOut(duration: 300.ms),
                ),
              ),
            // Top gradient
            Container(
              height: 92 + MediaQuery.of(context).viewPadding.top,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Colors.transparent],
                ),
              ),
            ),
            Align(
                  alignment: Alignment.topCenter,
                  child: SafeArea(
                    child: _HelpMessageWidget(
                      message: context.l10n.scan_help_message,
                    ),
                  ),
                )
                .animate(target: _isReceivingData ? 0 : 1)
                .fade(delay: 1.seconds, begin: -0.5)
                .moveY(delay: 1.seconds),
            Align(
                  alignment: Alignment.topCenter,
                  child: SafeArea(
                    child: _HelpMessageWidget(
                      message: context.l10n.low_speed_warning,
                    ),
                  ),
                )
                .animate(target: _showLowSpeedWarning ? 1 : 0)
                .fade(delay: 300.ms, begin: -0.5)
                .moveY(delay: 300.ms),
            ScanProgressWidget(
              chunkCount: _decodedChunkCount,
              speed: '${_speed.toStringAsFixed(1)}kB/s',
              show: _decodedChunkCount > 0,
              info: _statusMessage,
              progress: _progress,
              onTapCancel: _reset,
            ),
            // Speed bar
            if (_speed > 0)
              Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 80,
                ),
                child: AnimatedContainer(
                  duration: 300.milliseconds,
                  curve: Curves.easeInOut,
                  height: 3,
                  width: MediaQuery.of(context).size.width * (_speed / 100),
                  color: context.color.primary,
                ),
              ),
            if (_loadingResult)
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: const CircularProgressIndicator.adaptive(),
                ),
              ),
          ],
        ),
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
      _updateLowSpeedWarning();
    });
  }

  void _updateLowSpeedWarning() {
    if (!_isReceivingData) return;
    if (_speed >= 40) {
      _lowSpeedStartTime = null;
      if (_showLowSpeedWarning) {
        setState(() => _showLowSpeedWarning = false);
      }
    } else {
      _lowSpeedStartTime ??= DateTime.now();
      if (DateTime.now().difference(_lowSpeedStartTime!).inSeconds >= 2 &&
          !_showLowSpeedWarning) {
        setState(() => _showLowSpeedWarning = true);
      }
    }
  }

  void _handleMultiscan(Codes codes) {
    codes.codes.forEach(_handleScan);
    // After handling, so the codes that start a transfer count towards it.
    DecodeStats.instance.recordCodesRead(codes.codes.length);
  }

  void _handleScan(Code result) {
    if (!_shouldScan) {
      return;
    }

    if (_decoder.complete) {
      _shouldScan = false;
      return;
    }

    final (:action, :frame) = _tracker.handle(
      result.rawBytes,
      DateTime.now(),
      busy: _loadingResult,
    );
    switch (action) {
      case ScanAction.foreign:
        _handleRegularQRCodeResult(result.text);
      case ScanAction.updateRequired:
        _showUpdateRequired(context.l10n.update_required_msg);
      case ScanAction.senderUpdateRequired:
        _showUpdateRequired(context.l10n.sender_update_required_msg);
      case ScanAction.ignore:
        break;
      case ScanAction.switchTransfer:
        _restartTransfer();
        _startTransfer(frame!);
        DecodeStats.instance.recordPacket(frame.data);
      case ScanAction.start:
        _startTransfer(frame!);
        DecodeStats.instance.recordPacket(frame.data);
      case ScanAction.decode:
        _decoder.decodeChunk(frame!);
        DecodeStats.instance.recordPacket(frame.data);
    }
  }

  /// Sets up a new transfer from its first frame and decodes that frame.
  void _startTransfer(BlastQrcodeData frame) {
    DecodeStats.instance.startTransfer(frame.transferLength);
    // The decoder locks onto this frame's transfer synchronously, so the
    // metadata below always describes the transfer being decoded.
    _decoder.decodeChunk(frame);
    _fileMetadata = ReceivingFileMetadata(
      size: frame.transferLength,
      isCompressed: frame.isCompressedData,
      isEncrypted: frame.isEncrypted,
    );
    setState(() {
      _isReceivingData = true;
      _statusMessage = frame.isEncrypted
          ? context.l10n.receiving_encrypted
          : context.l10n.receiving_generic;
    });
    _latestScanStartTime = DateTime.now();
    debugPrint('Scanning file with: ${_fileMetadata.toString()}');
    _lockFocus();
  }

  /// Drops the current transfer's progress and starts on a new one right
  /// away (no pause, unlike [_reset]).
  void _restartTransfer() {
    debugPrint('Switching to a new transfer');
    _decoder.reset();
    _fileMetadata = null;
    _progress = 0;
    _decodedChunkCount = 0;
    _dataLengthInLastPeriod = 0;
  }

  /// The stream can't be read until the receiver or sender updates.
  void _showUpdateRequired(String message) {
    _shouldScan = false;
    if (_appSettings.hapticFeedback) {
      HapticFeedback.heavyImpact();
    }
    showMessage(
      context: context,
      title: context.l10n.update_required_title,
      message: message,
      confirmTitle: context.l10n.ok,
    ).then((_) => _reset());
  }

  void _handleDecodeProgress(int chunkLen, int chunkCount, double progress) {
    DecodeStats.instance.recordNewCode(chunkLen);
    setState(() {
      _progress = progress;
      _dataLengthInLastPeriod += chunkLen;
      _decodedChunkCount = chunkCount;
    });

    // Hide bottom bar
    context.read<NavBarVisibility>().hide();

    if (_appSettings.hapticFeedback) {
      HapticFeedback.lightImpact();
    }
    if (_appSettings.soundFeedback) {
      _soundService.playChunkReceived(_progress, _speed);
    }

    if (_speedTimer?.isActive == false || _speedTimer == null) {
      _startSpeedTimer();
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
    setState(() {});
  }

  void _handleResult(Uint8List data) async {
    final metadata = _fileMetadata;
    if (metadata == null) {
      return;
    }
    DecodeStats.instance.completeTransfer();

    final elapsedTime =
        DateTime.now().difference(_latestScanStartTime).inMilliseconds / 1000;
    final transferredBytes = data.length;

    // Everything has arrived: play the completion tone now
    _playTransferComplete();

    if (metadata.isEncrypted) {
      final Uint8List? plain;
      try {
        plain = await _decrypt(data);
      } catch (error) {
        debugPrint('Failed to decrypt received file: $error');
        _showReceiveFailed();
        return;
      }
      if (plain == null || !mounted || _fileMetadata != metadata) {
        if (mounted && _fileMetadata == metadata) _reset();
        return;
      }
      data = plain;
    }
    _loadingResult = false;

    final itemsDirectory = await receivedFilesDirectory();

    final List<File> resultFiles;
    try {
      resultFiles = await saveReceivedFiles(
        data: data,
        gzipped: metadata.isCompressed,
        directory: itemsDirectory,
        tempDirectory: await appTempDirectory(),
      );
    } catch (error) {
      debugPrint('Failed to save received file: $error');
      _showReceiveFailed();
      return;
    }
    final fileWrappers = await Future.wait(
      resultFiles.map((f) => f.toFileWrapper()),
    );

    if (!mounted) {
      return;
    }

    final badgeCount = Provider.of<FileBadgeCount>(context, listen: false);
    for (var i = 0; i < fileWrappers.length; i++) {
      badgeCount.add();
    }

    _showResultSheet(
      fileWrappers,
      elapsedTime,
      transferredBytes,
      encrypted: metadata.isEncrypted,
    ).then((discarded) async {
      if (discarded != true && fileWrappers.length == 1) {
        final file = fileWrappers.single;
        final newFilename = sanitizeFileName(_renameController.text);
        if (mounted && newFilename != file.name) {
          final uniqueName = await resolveUniqueFileName(
            itemsDirectory,
            newFilename,
          );
          file.file.rename('${itemsDirectory.path}/$uniqueName');
        }
      }
      _reset();
    });
  }

  void _playTransferComplete() {
    if (_appSettings.hapticFeedback) {
      HapticFeedback.heavyImpact();
    }
    if (_appSettings.soundFeedback) {
      _soundService.playTransferComplete();
    }
  }

  /// Asks until the password is right, keeping the received data, so a wrong
  /// password never means scanning again. Returns null if cancelled; throws
  /// if the data is damaged or unsupported.
  Future<Uint8List?> _decrypt(Uint8List envelope) async {
    final metadata = _fileMetadata;
    var failed = false;
    var lastTried = '';

    _setCameraOn(false);
    try {
      while (_fileMetadata == metadata) {
        if (!mounted) return null;
        setState(() => _loadingResult = false);
        final password = await showPasswordSheet(
          context,
          initialText: failed ? lastTried : '',
          wrongPassword: failed,
        );
        if (password == null || !mounted || _fileMetadata != metadata) {
          return null;
        }
        final plain = await _tryDecrypt(envelope, password);
        if (plain != null) return plain;
        failed = true;
        lastTried = password;
      }
      return null;
    } finally {
      _setCameraOn(true);
    }
  }

  void _setCameraOn(bool on) {
    if (!mounted) return;
    setState(() {
      _showsReaderWidget = on;
      if (!on) {
        _cameraController = null;
        _focusLocked = false;
      }
    });
  }

  /// Null if [password] is wrong; other errors are rethrown.
  Future<Uint8List?> _tryDecrypt(Uint8List envelope, String password) async {
    setState(() => _loadingResult = true);
    try {
      return await TransferCrypto.decrypt(envelope, password);
    } on TransferCryptoError catch (error) {
      if (error == TransferCryptoError.wrongPassword) return null;
      rethrow;
    }
  }

  void _showReceiveFailed() {
    if (!mounted) return;
    if (_appSettings.hapticFeedback) {
      HapticFeedback.heavyImpact();
    }
    showMessage(
      context: context,
      title: context.l10n.error,
      message: context.l10n.receive_failed_msg,
      confirmTitle: context.l10n.ok,
    ).then((_) => _reset());
  }

  /// Completes with true if the user discarded the files.
  Future<bool?> _showResultSheet(
    List<FileWrapper> files,
    double timeInSeconds,
    int transferredBytes, {
    bool encrypted = false,
  }) async {
    final file = files.first;
    _renameController.text = file.name;
    final speed = ((transferredBytes / 1000) / timeInSeconds).toStringAsFixed(
      1,
    );
    return showSheet(
      context: context,
      title:
          '${context.l10n.received_in} ${timeInSeconds.toStringAsFixed(1)}s (${speed}kB/s)',
      body: Column(
        children: [
          if (encrypted)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedSquareLock02,
                    size: 18,
                    color: context.color.onSurface,
                  ),
                  Text(context.l10n.received_encrypted),
                ],
              ),
            ),
          if (files.length > 1) ...[
            FilesPreview(files: files),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(context.l10n.files_count(files.length)),
            ),
          ] else ...[
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
                      offset: const Offset(0, 2),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: file.buildThumbnail(context, size: 150),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _renameController,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  suffixIcon: Padding(
                    padding: const EdgeInsetsGeometry.all(12),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedEdit01,
                      color: context.color.onSurface,
                    ),
                  ),
                  contentPadding: const EdgeInsetsDirectional.fromSTEB(
                    48,
                    0,
                    0,
                    8,
                  ),
                ),
                onTap: () {
                  final dotIndex = _renameController.text.indexOf('.');
                  final selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: dotIndex > 0 ? dotIndex : 0,
                  );
                  _renameController.selection = selection;
                },
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              spacing: 8,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final badgeCount = Provider.of<FileBadgeCount>(
                        context,
                        listen: false,
                      );
                      for (final f in files) {
                        badgeCount.subtract();
                        await f.file.delete();
                      }
                      if (mounted) {
                        Navigator.of(context).pop(true);
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
    setState(() => _shouldScan = false);
    if (_appSettings.hapticFeedback) {
      HapticFeedback.heavyImpact();
    }
    if (_appSettings.soundFeedback) {
      _soundService.playQRCodeResult();
    }

    final content = text ?? '';
    showSheet(
      context: context,
      title: context.l10n.result,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 4, 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: context.color.surfaceContainer,
                border: Border.all(color: context.color.outline),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      content,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: context.l10n.copy,
                    onPressed: () => _copyToClipboard(content),
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedCopy01,
                      color: context.color.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _saveRegularQRCode(content),
              child: Text(context.l10n.save),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n.dismiss),
            ),
          ],
        ),
      ),
    ).then((_) {
      _reset();
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.copied)));
  }

  Future<void> _saveRegularQRCode(String text) async {
    final navigator = Navigator.of(context);
    final badgeCount = Provider.of<FileBadgeCount>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await saveScannedQrCode(text, await qrCodesDirectory());
      badgeCount.add();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }
    navigator.pop();
  }

  void _reset() async {
    DecodeStats.instance.endTransfer();
    _shouldScan = false;
    _loadingResult = false;
    _statusMessage = '';
    _progress = 0;
    _speed = 0;
    _decodedChunkCount = 0;
    _fileMetadata = null;
    _tracker.reset();
    _renameController.text = '';
    _showLowSpeedWarning = false;
    _lowSpeedStartTime = null;
    setState(() {});

    _speedTimer?.cancel();
    _decoder.reset();

    _unlockFocus();

    // Re-show bottom navigation
    context.read<NavBarVisibility>().show();

    // Wait a second to start scanning again
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _shouldScan = true;
        _isReceivingData = false;
      });
    }
  }

  /// Tapping again and again usually means scanning is stuck, which focusing
  /// doesn't fix but reopening the camera does.
  void _onPreviewTap(Offset tap) {
    _taps =
        _sinceLastTap.isRunning &&
            _sinceLastTap.elapsed < const Duration(milliseconds: 600)
        ? _taps + 1
        : 1;
    _sinceLastTap
      ..reset()
      ..start();
    if (_taps < 3) {
      _focusAt(tap);
      return;
    }
    _taps = 0;
    _readerKey.currentState?.restart();
  }

  void _focusAt(Offset tap) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    if (!Platform.isIOS && !Platform.isAndroid) return;
    final size =
        (_readerKey.currentContext?.findRenderObject() as RenderBox?)?.size;
    if (size == null || size.isEmpty) return;

    // QrScanner cover-fits the preview, centered in its box.
    final value = controller.value;
    final orientation =
        value.lockedCaptureOrientation ?? value.deviceOrientation;
    final isLandscape =
        orientation == DeviceOrientation.landscapeLeft ||
        orientation == DeviceOrientation.landscapeRight;
    final previewAspect = isLandscape
        ? value.aspectRatio
        : 1 / value.aspectRatio;
    final preview = size.width / size.height > previewAspect
        ? Size(size.width, size.width / previewAspect)
        : Size(size.height * previewAspect, size.height);
    final point = Offset(
      ((tap.dx - (size.width - preview.width) / 2) / preview.width).clamp(0, 1),
      ((tap.dy - (size.height - preview.height) / 2) / preview.height).clamp(
        0,
        1,
      ),
    );

    if (value.focusPointSupported) {
      unawaited(controller.setFocusPoint(point).catchError((_) {}));
    }
    // A fixed exposure from the Debug page shouldn't follow taps.
    if (value.exposurePointSupported && !_fixedExposure) {
      unawaited(controller.setExposurePoint(point).catchError((_) {}));
    }
    // Setting an exposure point resets the iPhone exposure setup.
    _configureCamera();
    setState(() => _focusIndicator = tap);
  }

  // camera_desktop fails above low on Linux:
  // https://github.com/hugocornellier/camera_desktop/issues/8
  ResolutionPreset get _cameraResolution =>
      Platform.isLinux ? ResolutionPreset.low : _appSettings.cameraResolution;

  int? get _cameraFps =>
      Platform.isIOS || Platform.isAndroid ? _appSettings.cameraFps : null;

  void _onCameraChanged(CameraController? controller) {
    _cameraController = controller;
    _focusLocked = false;
    if (controller != null) {
      _openedFps = controller.mediaSettings.fps;
      _updateCameraLabel();
    }
    _configureCamera();
  }

  /// A fixed exposure from the Debug page, which automatic exposure mustn't
  /// override.
  bool get _fixedExposure =>
      Platform.isIOS && (_appSettings.debugExposureMs ?? 0) > 0;

  void _configureCamera() {
    if (!Platform.isIOS || _cameraController == null) return;
    final exposure = _appSettings.debugExposureMs;
    unawaited(
      ScanCamera.configure(
        videoHdr: _appSettings.debugVideoHdr,
        maxExposureMs: exposure == null
            ? ScanCamera.defaultMaxExposureMs
            : null,
        exposureMs: (exposure ?? 0) > 0 ? exposure : null,
      ).catchError((Object e) => debugPrint('Camera setup failed: $e')),
    );
  }

  void _lockFocus() {
    if (_focusLocked || _cameraController == null) return;
    // Desktop cameras have no focus or exposure controls.
    if (!Platform.isIOS && !Platform.isAndroid) return;
    _focusLocked = true;
    unawaited(_cameraController!.setFocusMode(FocusMode.locked));
    if (_fixedExposure) {
      _configureCamera();
      return;
    }
    unawaited(_cameraController!.setExposureMode(ExposureMode.auto));
    unawaited(_cameraController!.setExposureOffset(-0.5));
    _configureCamera();
  }

  void _unlockFocus() {
    _focusLocked = false;
    if (_cameraController != null && (Platform.isIOS || Platform.isAndroid)) {
      unawaited(_cameraController!.setFocusMode(FocusMode.auto));
      if (_fixedExposure) return;
      unawaited(_cameraController!.setExposureMode(ExposureMode.auto));
      unawaited(_cameraController!.setExposureOffset(0.0));
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

class _HelpMessageWidget extends StatelessWidget {
  const _HelpMessageWidget({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(64),
          color: Colors.black.withAlpha(140),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(75),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          spacing: 12,
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedInformationCircle,
              color: Colors.white,
            ),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class ScanProgressWidget extends StatelessWidget {
  const ScanProgressWidget({
    super.key,
    required this.progress,
    required this.info,
    required this.onTapCancel,
    required this.chunkCount,
    required this.speed,
    required this.show,
  });

  final double progress;
  final String info;
  final int chunkCount;
  final String speed;
  final bool show;
  final void Function() onTapCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          child:
              Container(
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(36),
                      color: context.color.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(45),
                          spreadRadius: 0,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
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
                                  strokeCap: StrokeCap.round,
                                  value: progress > 1 ? null : progress,
                                  color: context.color.primary,
                                  backgroundColor: context.color.outline,
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: context.color.surface,
                                ),
                                width: 44,
                                height: 44,
                              ),
                              Text(
                                '${(progress.clamp(0, 1) * 100).floor()}%',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Jersey25',
                                  color: context.color.onSurface,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                progress > 1
                                    ? context.l10n.keep_scanning_msg
                                    : info,
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: 'Jersey25',
                                  color: context.color.onSurface,
                                  height: 1,
                                ),
                              ),
                              Text(
                                '$chunkCount | $speed',
                                style: TextStyle(
                                  color: context.color.onSurface,
                                ),
                                textAlign: TextAlign.end,
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: onTapCancel,
                            style: IconButton.styleFrom(
                              minimumSize: const Size(24, 24),
                              maximumSize: const Size(32, 32),
                              backgroundColor: context.color.primaryContainer,
                              foregroundColor: context.color.onSurface,
                            ),
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.clear, size: 16),
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate(target: show ? 1 : 0)
                  .fade()
                  .slideY(
                    begin: 0.75,
                    end: 0,
                    duration: 300.ms,
                    curve: Curves.easeOutBack,
                  ),
        ),
        // The bottom tabs overlap the page on phones; desktop has none.
        SizedBox(height: max(16, MediaQuery.of(context).padding.bottom - 64)),
      ],
    );
  }
}
