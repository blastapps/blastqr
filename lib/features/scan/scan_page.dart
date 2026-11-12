import 'dart:async';
import 'dart:io';

import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/crypto/transfer_crypto.dart';
import 'package:blast_qr/extensions/string_extension.dart';
import 'package:blast_qr/features/scan/decode_stats.dart';
import 'package:blast_qr/features/scan/received_file_writer.dart';
import 'package:blast_qr/features/scan/scan_camera.dart';
import 'package:blast_qr/features/scan/transfer_tracker.dart';
import 'package:blast_qr/features/scan/widgets/camera_permission_message.dart';
import 'package:blast_qr/features/scan/widgets/feedback_toggles.dart';
import 'package:blast_qr/features/scan/widgets/focus_ring.dart';
import 'package:blast_qr/features/scan/widgets/help_message.dart';
import 'package:blast_qr/features/scan/widgets/password_sheet.dart';
import 'package:blast_qr/features/scan/widgets/qr_result_sheet.dart';
import 'package:blast_qr/features/scan/widgets/received_files_sheet.dart';
import 'package:blast_qr/features/scan/widgets/scan_progress.dart';
import 'package:blast_qr/features/scan/widgets/qr_scanner.dart';
import 'package:blast_qr/features/settings/settings_page.dart';
import 'package:blast_qr/file_badge_count.dart';
import 'package:blast_qr/file_name_utils.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/blast_qrcode_data.dart';
import 'package:blast_qr/model/file_extension.dart';
import 'package:blast_qr/model/receiving_file_metadata.dart';
import 'package:blast_qr/nav_bar_visibility.dart';
import 'package:blast_qr/platform_support.dart';
import 'package:blast_qr/raptorq/raptorq_decoder.dart';
import 'package:blast_qr/received_files_directory.dart';
import 'package:blast_qr/sound_feedback.dart';
import 'package:blast_qr/temp_files.dart';
import 'package:blast_qr/theme.dart';
import 'package:blast_qr/widgets/bottom_sheets.dart';
import 'package:blast_qr/widgets/circle_button.dart';
import 'package:blast_qr/widgets/logo_widget.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:hugeicons/hugeicons.dart';
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
  bool _cameraDenied = false;
  bool _showLowSpeedWarning = false;
  DateTime? _lowSpeedStartTime;
  late SoundFeedbackService _soundService;
  late AppSettings _appSettings;
  late final NavBarVisibility _navBar;
  DateTime _latestScanStartTime = DateTime.now();
  ReceivingFileMetadata? _fileMetadata;

  /// Decides which transfer the scanned frames belong to.
  final _tracker = TransferTracker();
  CameraController? _cameraController;
  bool _focusLocked = false;
  final _readerKey = GlobalKey<QrScannerState>();
  Offset? _focusIndicator;

  // Focus locks once a transfer's codes have been read without a break for
  // a while. Locking on the first code would often lock it while the phone
  // is still moving into place.
  static const _steadyFor = Duration(seconds: 1);
  static const _maxReadGap = Duration(milliseconds: 500);
  DateTime? _steadySince;
  DateTime? _lastReadAt;

  /// Quick taps in a row; the second restarts the camera.
  int _taps = 0;
  final _sinceLastTap = Stopwatch();

  /// Where the camera refocuses once it's reopened by a double tap.
  Offset? _refocusAt;

  @override
  void initState() {
    super.initState();
    _createDecoder();
    _soundService = SoundFeedbackService();
    _navBar = context.read<NavBarVisibility>();
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
        '$fps FPS${_cameraFps == null ? ' (auto)' : ''}',
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
    // Leaving mid-transfer skips _reset. The tree is locked while disposing.
    WidgetsBinding.instance.addPostFrameCallback((_) => _navBar.show());
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
          leadingWidth: isDesktopOS ? 56 : 104,
          leading: FeedbackToggles(
            appSettings: appSettings,
            colors: darkColors,
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
                          cropPreview: appSettings.cropCameraPreview,
                          autoRestart: _shouldScan,
                          onCodes: _handleMultiscan,
                          onCameraChanged: _onCameraChanged,
                          onFrame: DecodeStats.instance.record,
                          onPermissionChanged: (denied) {
                            setState(() => _cameraDenied = denied);
                          },
                        ),
                      ),
                    )
                  : const SizedBox(),
            ),
            if (_focusIndicator case final tap?)
              Positioned(
                left: tap.dx - 32,
                top: tap.dy - 32,
                child: FocusRing(
                  key: ValueKey(tap),
                  onComplete: () {
                    if (mounted && _focusIndicator == tap) {
                      setState(() => _focusIndicator = null);
                    }
                  },
                ),
              ),
            if (_cameraDenied)
              Positioned.fill(
                child: CameraPermissionMessage(
                  onEnable: () => _readerKey.currentState?.enableCamera(),
                ),
              ),
            // Top gradient
            if (!context.useDesktopLayout)
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
                    child: HelpMessage(message: context.l10n.scan_help_message),
                  ),
                )
                .animate(target: _isReceivingData || _cameraDenied ? 0 : 1)
                .fade(delay: 1.seconds, begin: -0.5)
                .moveY(
                  delay: 1.seconds,
                  begin: -24,
                  end: context.useDesktopLayout ? -16 : 0,
                ),
            Align(
                  alignment: Alignment.topCenter,
                  child: SafeArea(
                    child: HelpMessage(message: context.l10n.low_speed_warning),
                  ),
                )
                .animate(target: _showLowSpeedWarning ? 1 : 0)
                .fade(delay: 300.ms, begin: -0.5)
                .moveY(
                  delay: 300.ms,
                  begin: -24,
                  end: context.useDesktopLayout ? -16 : 0,
                ),
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
    if (codes.codes.isNotEmpty) _lockFocusOnceSteady();
  }

  void _lockFocusOnceSteady() {
    final now = DateTime.now();
    final last = _lastReadAt;
    _lastReadAt = now;
    if (last == null || now.difference(last) > _maxReadGap) {
      _steadySince = now;
    }
    if (_isReceivingData && now.difference(_steadySince!) >= _steadyFor) {
      _lockFocus();
    }
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
    _navBar.hide();

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
    _showLowSpeedWarning = false;
    _lowSpeedStartTime = null;
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

    showReceivedFilesSheet(
      context,
      files: fileWrappers,
      renameController: _renameController,
      timeInSeconds: elapsedTime,
      transferredBytes: transferredBytes,
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

  void _handleRegularQRCodeResult(String? text) async {
    setState(() => _shouldScan = false);
    if (_appSettings.hapticFeedback) {
      HapticFeedback.heavyImpact();
    }
    if (_appSettings.soundFeedback) {
      _soundService.playQRCodeResult();
    }

    showQrResultSheet(context, text ?? '').then((_) => _reset());
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
    _navBar.show();

    // Wait a second to start scanning again
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _shouldScan = true;
        _isReceivingData = false;
      });
    }
  }

  /// A quick second tap usually means scanning is stuck, which focusing
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
    if (_taps < 2) {
      _focusAt(tap);
      return;
    }
    _taps = 0;
    _refocusAt = tap;
    _readerKey.currentState?.restart();
  }

  void _focusAt(Offset tap) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    if (!Platform.isIOS && !Platform.isAndroid) return;
    final size =
        (_readerKey.currentContext?.findRenderObject() as RenderBox?)?.size;
    if (size == null || size.isEmpty) return;

    // QrScanner cover- or contain-fits the preview, centered in its box.
    final value = controller.value;
    final orientation =
        value.lockedCaptureOrientation ?? value.deviceOrientation;
    final isLandscape =
        orientation == DeviceOrientation.landscapeLeft ||
        orientation == DeviceOrientation.landscapeRight;
    final previewAspect = isLandscape
        ? value.aspectRatio
        : 1 / value.aspectRatio;
    final wider = size.width / size.height > previewAspect;
    final preview = wider == _appSettings.cropCameraPreview
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
    _lastReadAt = null;
    if (controller != null) {
      _openedFps = controller.mediaSettings.fps;
      _updateCameraLabel();
    }
    _configureCamera();
    final refocusAt = _refocusAt;
    if (controller != null && refocusAt != null) {
      _refocusAt = null;
      _focusAt(refocusAt);
    }
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
    _lastReadAt = null;
    if (_cameraController != null && (Platform.isIOS || Platform.isAndroid)) {
      unawaited(_cameraController!.setFocusMode(FocusMode.auto));
      if (_fixedExposure) return;
      unawaited(_cameraController!.setExposureMode(ExposureMode.auto));
      unawaited(_cameraController!.setExposureOffset(0.0));
    }
  }
}
