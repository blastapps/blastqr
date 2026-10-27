import 'dart:async';

import 'package:blast_qr/acoustic_ack_listener.dart';
import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/features/help/help_page.dart';
import 'package:blast_qr/features/send/widgets/acoustic_success_overlay.dart';
import 'package:blast_qr/features/send/widgets/file_header_widget.dart';
import 'package:blast_qr/features/send/widgets/file_too_large_alert_widget.dart';
import 'package:blast_qr/features/send/widgets/raptorq_qr_streaming_widget.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blast_qr/widgets/circle_button.dart';
import 'package:blast_qr/widgets/password_widgets.dart';
import 'package:blast_qr/widgets/strike_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class QrPage extends StatefulWidget {
  const QrPage({
    super.key,
    required this.file,
    this.bundledFiles = const [],
    this.password,
    this.fileName,
  });

  static const largeFileBytes = 600000;

  final FileWrapper file;

  /// The original files when [file] is a bundle of several.
  final List<FileWrapper> bundledFiles;

  bool get isBundle => bundledFiles.isNotEmpty;

  final String? password;

  final String? fileName;

  @override
  State<QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> {
  final _qrController = RaptorQrStreamingWidgetController();

  bool get _isLargeFile => widget.file.size > QrPage.largeFileBytes;
  bool _largeFileAcknowledged = false;
  bool _shouldCompressImage = false;
  int? _compressedSize;

  static const _fpsOptions = [15, 16, 20, 22, 25, 30];

  /// Session override of the settings fps, set by the FPS button.
  int? _fps;

  bool _fullscreenMode = false;

  AcousticAckListener? _acousticListener;
  StreamSubscription<void>? _acousticSub;
  Timer? _listenerDelayTimer;
  bool _completionDetected = false;
  bool _dismissed = false;

  bool get _showsPasswordButton =>
      !_fullscreenMode && widget.password != null && !_completionDetected;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLargeFile && !_largeFileAcknowledged) {
      final appSettings = Provider.of<AppSettings>(context, listen: false);
      if (appSettings.alwaysCompressImages) {
        _largeFileAcknowledged = true;
        _shouldCompressImage = true;
      }
    }
  }

  @override
  void dispose() {
    _listenerDelayTimer?.cancel();
    _acousticSub?.cancel();
    _acousticListener?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qrBoxHeight = MediaQuery.of(context).size.width;
    final appSettings = Provider.of<AppSettings>(context);
    final encodeSettings = Provider.of<EncodeSettings>(context);
    final fps = _fps ?? encodeSettings.playbackFps;
    final colors = Theme.of(context).colorScheme;
    final micOn = appSettings.acousticDetection;
    final iconColor = context.color.onPrimaryContainer;
    return Scaffold(
      backgroundColor: context.color.primaryContainer,
      body: SafeArea(
        child: Column(
          children: [
            if (!_fullscreenMode)
              FileHeaderWidget(
                file: widget.file,
                name: widget.fileName,
                bundledFiles: widget.bundledFiles,
                onTapDismiss: _dismiss,
                compressedSize: _compressedSize,
                encrypted: widget.password != null,
              ),
            Expanded(
              flex: _fullscreenMode ? 1 : 0,
              key: const ValueKey('qr_container'),
              child: Align(
                alignment: Alignment.topCenter,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: context.color.outline,
                          width: 2,
                        ),
                        color: _isLargeFile && !_largeFileAcknowledged
                            ? context.color.primaryContainer
                            : Colors.white,
                      ),
                      child: SizedBox(
                        height: _fullscreenMode ? null : qrBoxHeight + 16,
                        child: _isLargeFile && !_largeFileAcknowledged
                            ? FileTooLargeAlertWidget(
                                estimatedSlowestTime: widget.file
                                    .getEstimateTransferTime(8),
                                fileType: widget.file.type,
                                onAcknowledge: () {
                                  setState(() {
                                    _largeFileAcknowledged = true;
                                  });
                                },
                                onRequestCompressedImage: (quality) {
                                  setState(() {
                                    _largeFileAcknowledged = true;
                                    _shouldCompressImage = true;
                                  });
                                },
                              )
                            : Consumer<EncodeSettings>(
                                builder: (context, state, child) {
                                  return RaptorQrStreamingWidget(
                                    controller: _qrController,
                                    file: widget.file,
                                    mtu: state.mtu,
                                    fps: fps,
                                    imageCompressionSettings:
                                        _shouldCompressImage
                                        ? appSettings.imageCompressionSettings
                                        : null,
                                    password: widget.password,
                                    fileName: widget.fileName,
                                    isBundle: widget.isBundle,
                                    fill: _fullscreenMode,
                                    onTap: _onToggleFullscreen,
                                    onStart: (size) => _onStart(
                                      size,
                                      multipleQrCodes: state.multipleQrCodes,
                                      fps: fps,
                                      mtu: state.mtu,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                    if (_completionDetected)
                      Positioned.fill(
                        child: AcousticSuccessOverlay(
                          onKeepShowing: _onKeepShowingQr,
                          onDone: _dismiss,
                          password: widget.password,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (!_fullscreenMode)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleButton(
                            size: 64,
                            icon: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$fps',
                                  style: const TextStyle(
                                    height: 1,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'FPS',
                                  style: TextStyle(fontSize: 10, height: 1),
                                ),
                              ],
                            ),
                            backgroundColor: colors.tertiaryContainer,
                            onPressed: () => _cycleFps(fps),
                          ),
                          CircleButton(
                            size: 64,
                            icon: const HugeIcon(
                              icon: HugeIcons.strokeRoundedLayoutGrid,
                            ),
                            backgroundColor: colors.tertiaryContainer,
                            onPressed: _onToggleFullscreen,
                          ),
                          CircleButton(
                            size: 64,
                            icon: CustomPaint(
                              foregroundPainter: micOn
                                  ? null
                                  : StrikePainter(
                                      color: iconColor.withValues(alpha: 0.5),
                                      gapColor: colors.tertiaryContainer,
                                    ),
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedMic02,
                                color: micOn
                                    ? iconColor
                                    : iconColor.withValues(alpha: 0.5),
                              ),
                            ),
                            backgroundColor: colors.tertiaryContainer,
                            onPressed: () => _toggleAcousticDetection(!micOn),
                          ),
                          CircleButton(
                            size: 64,
                            icon: const HugeIcon(
                              icon: HugeIcons.strokeRoundedHelpCircle,
                            ),
                            backgroundColor: colors.tertiaryContainer,
                            onPressed: _showHelp,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_showsPasswordButton)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: PasswordButton(password: widget.password!),
                        ),
                    ],
                  ),
                ),
              ),

            if (!_fullscreenMode)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: ElevatedButton(
                  onPressed: _dismiss,
                  child: Row(
                    spacing: 8,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Text(context.l10n.done)],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onStart(
    int size, {
    required bool multipleQrCodes,
    required int fps,
    required int mtu,
  }) {
    setState(() => _compressedSize = size);
    if (multipleQrCodes) _enterFullscreen();
    _startAcousticListener(
      fileSize: size,
      fps: fps,
      mtu: mtu,
      codesPerFrame: _maxQrCodesPerFrame(),
    );
  }

  void _startAcousticListener({
    int? fileSize,
    int fps = 0,
    int mtu = 0,
    int codesPerFrame = 1,
  }) {
    final appSettings = Provider.of<AppSettings>(context, listen: false);
    if (!appSettings.acousticDetection) return;

    _acousticSub?.cancel();
    _listenerDelayTimer?.cancel();

    void startNow() {
      if (!mounted) return;
      _acousticListener ??= AcousticAckListener();
      _acousticSub = _acousticListener!.onDetected.listen((_) {
        if (mounted) {
          if (_fullscreenMode) _exitFullscreen();
          setState(() => _completionDetected = true);
          _acousticListener?.stop();
        }
      });
      _acousticListener!.start();
    }

    if (fileSize != null) {
      // Estimate earliest possible completion based on actual fps, mtu, and
      // number of codes displayed per frame, then subtract a 4 s buffer so
      // we never miss the tone.
      final bestCaseKBps = fps * mtu * codesPerFrame / 1000.0;
      debugPrint('Best case speed: $bestCaseKBps kB/s');
      const bufferSeconds = 4.0;
      final estimatedSeconds = fileSize / (bestCaseKBps * 1000);
      final delaySeconds = (estimatedSeconds - bufferSeconds).clamp(
        0.0,
        double.infinity,
      );
      _listenerDelayTimer = Timer(
        Duration(milliseconds: (delaySeconds * 1000).round()),
        startNow,
      );
      return;
    }
    startNow();
  }

  void _cycleFps(int current) {
    final options = {..._fpsOptions, current}.toList()..sort();
    final next = options[(options.indexOf(current) + 1) % options.length];
    setState(() => _fps = next);
  }

  Future<void> _toggleAcousticDetection(bool on) async {
    final appSettings = Provider.of<AppSettings>(context, listen: false);
    if (on) {
      final granted = await AcousticAckListener.requestPermission();
      if (!mounted || !granted) return;
      appSettings.updateAcousticDetection(true);
      if (!_completionDetected) _startAcousticListener();
    } else {
      appSettings.updateAcousticDetection(false);
      _listenerDelayTimer?.cancel();
      _acousticSub?.cancel();
      _acousticListener?.stop();
    }
  }

  void _showHelp() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => const HelpPage(),
      ),
    );
  }

  void _onKeepShowingQr() {
    setState(() => _completionDetected = false);
    _startAcousticListener(); // no fileSize → no delay, position unknown
  }

  void _enterFullscreen() {
    setState(() => _fullscreenMode = true);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  void _exitFullscreen() {
    setState(() => _fullscreenMode = false);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _onToggleFullscreen() {
    if (_fullscreenMode) {
      _exitFullscreen();
    } else {
      _enterFullscreen();
    }
  }

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _cleanup();
    Navigator.of(context).pop();
  }

  /// Mirrors the column logic in [_FlexibleGrid]: 2 rows × 1–3 columns based
  /// on the current screen aspect ratio.
  int _maxQrCodesPerFrame() {
    final size = MediaQuery.of(context).size;
    final aspectRatio = size.width / size.height;
    final int columns;
    if (aspectRatio < 0.8) {
      columns = 1;
    } else if (aspectRatio < 1.4) {
      columns = 2;
    } else {
      columns = 3;
    }
    return 2 * columns;
  }

  void _cleanup() {
    _listenerDelayTimer?.cancel();
    _acousticSub?.cancel();
    _acousticListener?.stop();
    _qrController.stopAnimation();
  }
}
