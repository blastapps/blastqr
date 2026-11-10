import 'dart:async';

import 'package:blast_qr/acoustic_ack_listener.dart';
import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/features/help/help_page.dart';
import 'package:blast_qr/features/send/send_files.dart';
import 'package:blast_qr/features/send/send_plan.dart';
import 'package:blast_qr/features/send/widgets/acoustic_success_overlay.dart';
import 'package:blast_qr/features/send/widgets/file_header_widget.dart';
import 'package:blast_qr/features/send/widgets/file_too_large_alert_widget.dart';
import 'package:blast_qr/features/send/widgets/raptorq_qr_streaming_widget.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blast_qr/platform_support.dart';
import 'package:blast_qr/widgets/circle_button.dart';
import 'package:blast_qr/widgets/password_widgets.dart';
import 'package:blast_qr/widgets/strike_painter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:window_manager/window_manager.dart';

class QrPage extends StatefulWidget {
  const QrPage({
    super.key,
    required this.files,
    this.password,
    this.fileName,
    required this.compressImages,
  });

  /// The files to send. Several are zipped into one bundle first.
  final List<FileWrapper> files;

  final String? password;

  final String? fileName;

  /// Whether photos are compressed, as chosen with the HD toggle.
  final bool compressImages;

  @override
  State<QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> with WindowListener {
  final _qrController = RaptorQrStreamingWidgetController();
  final _qrBoxKey = GlobalKey();

  late final SendPlan _plan;
  int? _compressedSize;

  static const _fpsOptions = [15, 16, 20, 22, 25, 30];

  /// Session override of the settings fps, set by the FPS button.
  int? _fps;

  bool _fullscreenMode = false;

  /// Whether this page put the desktop window in full screen, so leaving
  /// only undoes that and not a full screen the user set up.
  bool _windowFullScreen = false;

  /// For telling a double tap on the codes from a single one.
  DateTime? _lastTap;
  bool _windowFullScreenBeforeTap = false;
  bool _playbackStarted = false;

  AcousticAckListener? _acousticListener;
  StreamSubscription<void>? _acousticSub;
  Timer? _listenerDelayTimer;
  bool _ackArmed = false;
  bool _completionDetected = false;
  bool _dismissed = false;

  bool get _showsPasswordButton =>
      !_fullscreenMode && widget.password != null && !_completionDetected;

  @override
  void initState() {
    super.initState();
    if (isDesktopOS) windowManager.addListener(this);
    WakelockPlus.enable();
    _plan = SendPlan(
      widget.files,
      compressImages: widget.compressImages,
      zip: _zip,
    )..addListener(() => setState(() {}));
  }

  /// Zips the files. The page closes if the bundle is too large to send.
  Future<FileWrapper> _zip({required bool compressImages}) async {
    final settings = Provider.of<AppSettings>(
      context,
      listen: false,
    ).imageCompressionSettings;
    final bundle = await createSendBundle(
      widget.files,
      icSettings: compressImages ? settings : null,
    );
    if (mounted) {
      final tooLarge = transferTooLargeMessage(context, bundle.size);
      if (tooLarge != null) _closeTooLarge(tooLarge);
    }
    return bundle;
  }

  Future<void> _closeTooLarge(String message) async {
    await showFileTooLarge(context, message);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    if (isDesktopOS) {
      windowManager.removeListener(this);
      if (_windowFullScreen) windowManager.setFullScreen(false);
    }
    _plan.dispose();
    _listenerDelayTimer?.cancel();
    _acousticSub?.cancel();
    _acousticListener?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qrBox = _buildQrBox(context);
    // Like the CLI: up and down step the fps.
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => _stepFps(1),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => _stepFps(-1),
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_fullscreenMode) _exitFullscreen();
        },
      },
      child: Focus(autofocus: true, child: _buildScaffold(context, qrBox)),
    );
  }

  Widget _buildScaffold(BuildContext context, Widget qrBox) {
    return Scaffold(
      backgroundColor: context.color.primaryContainer,
      body: SafeArea(
        child: _fullscreenMode
            ? qrBox
            : Column(
                children: [
                  FileHeaderWidget(
                    files: widget.files,
                    name: widget.fileName,
                    onTapDismiss: _dismiss,
                    // A bundle's images are compressed when it's built.
                    compressedSize:
                        _compressedSize ??
                        (_plan.isBundle ? _plan.file?.size : null),
                    encrypted: widget.password != null,
                  ),
                  // The QR box takes what the controls leave, so both stay
                  // visible however wide or short the window is.
                  Expanded(
                    child: Column(
                      children: [
                        Flexible(child: qrBox),
                        // Space is kept while the codes are generated, so the
                        // QR box doesn't shrink when playback starts.
                        if (!_completionDetected && !_plan.showsWarning)
                          Visibility(
                            visible: _playbackStarted,
                            maintainSize: true,
                            maintainAnimation: true,
                            maintainState: true,
                            child: _buildControls(context),
                          ),
                      ],
                    ),
                  ),
                  if (!context.useDesktopLayout)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: ElevatedButton(
                        onPressed: _dismiss,
                        child: Text(context.l10n.done),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  /// The QR codes, or the large file prompt before they start. Keyed so the
  /// animation keeps running when toggling fullscreen moves it in the tree.
  Widget _buildQrBox(BuildContext context) {
    final appSettings = Provider.of<AppSettings>(context);
    return Stack(
      key: _qrBoxKey,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: context.color.outline, width: 2),
            color: _plan.showsWarning
                ? context.color.primaryContainer
                : Colors.white,
          ),
          child: _plan.showsWarning
              ? FileTooLargeAlertWidget(
                  transferBytes: _plan.size,
                  compressibleImages: _plan.compressibleImages,
                  onAcknowledge: _plan.sendAsIs,
                  onRequestCompressedImage: (_) => _plan.sendCompressed(),
                )
              : _plan.file == null
              ? const Center(child: CircularProgressIndicator.adaptive())
              : Consumer<EncodeSettings>(
                  builder: (context, state, child) {
                    final mtu = state.mtuFor(_plan.size);
                    final fps = _fps ?? state.fpsFor(_plan.size);
                    return RaptorQrStreamingWidget(
                      controller: _qrController,
                      file: _plan.file!,
                      mtu: mtu,
                      fps: fps,
                      fill: _fullscreenMode,
                      imageCompressionSettings:
                          _plan.compressImages && !_plan.isBundle
                          ? appSettings.imageCompressionSettings
                          : null,
                      password: widget.password,
                      fileName: widget.fileName,
                      isBundle: _plan.isBundle,
                      onTap: _onTapCodes,
                      onStart: (size) => _onStart(
                        size,
                        multipleQrCodes: state.multipleQrCodes,
                        fps: fps,
                        mtu: mtu,
                      ),
                    );
                  },
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
    );
  }

  Widget _buildControls(BuildContext context) {
    final encodeSettings = Provider.of<EncodeSettings>(context);
    final fps = _fps ?? encodeSettings.fpsFor(_plan.size);
    final micOn = Provider.of<AppSettings>(context).acousticDetection;
    final colors = Theme.of(context).colorScheme;
    final iconColor = context.color.onPrimaryContainer;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                tooltip: context.l10n.qr_tooltip_fps,
              ),
              CircleButton(
                size: 64,
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowExpand),
                backgroundColor: colors.tertiaryContainer,
                onPressed: _onToggleFullscreen,
                tooltip: context.l10n.qr_tooltip_fullscreen,
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
                    icon: HugeIcons.strokeRoundedAudioWave01,
                    color: micOn ? iconColor : iconColor.withValues(alpha: 0.5),
                  ),
                ),
                backgroundColor: colors.tertiaryContainer,
                onPressed: () => _toggleAcousticDetection(!micOn),
                tooltip: micOn
                    ? context.l10n.qr_tooltip_tone_on
                    : context.l10n.qr_tooltip_tone_off,
              ),
              CircleButton(
                size: 64,
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedHelpCircle),
                backgroundColor: colors.tertiaryContainer,
                onPressed: _showHelp,
                tooltip: context.l10n.help,
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
    );
  }

  void _onStart(
    int size, {
    required bool multipleQrCodes,
    required int fps,
    required int mtu,
  }) {
    setState(() {
      _compressedSize = size;
      _playbackStarted = true;
    });
    if (multipleQrCodes) _enterFullscreen();
    _startAcousticListener(
      fileSize: size,
      fps: fps,
      mtu: mtu,
      codesPerFrame: RaptorQrStreamingWidget.maxCodesFor(
        MediaQuery.sizeOf(context),
      ),
    );
  }

  /// Starts the mic right away, because starting it blocks the main thread
  /// and would stutter the animation if done mid-transfer. Detections only
  /// count once the delay has passed.
  void _startAcousticListener({
    int? fileSize,
    int fps = 0,
    int mtu = 0,
    int codesPerFrame = 1,
  }) {
    final appSettings = Provider.of<AppSettings>(context, listen: false);
    if (!appSettings.acousticDetection) return;

    _listenerDelayTimer?.cancel();
    _ackArmed = false;

    if (_acousticListener == null) {
      _acousticListener = AcousticAckListener();
      _acousticSub = _acousticListener!.onDetected.listen((_) {
        if (!mounted || !_ackArmed) return;
        _ackArmed = false;
        if (_fullscreenMode) _exitFullscreen();
        setState(() => _completionDetected = true);
      });
    }
    _acousticListener!.start();

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
        () => _ackArmed = true,
      );
      return;
    }
    _ackArmed = true;
  }

  void _cycleFps(int current) {
    final options = _fpsOptionsWith(current);
    final next = options[(options.indexOf(current) + 1) % options.length];
    setState(() => _fps = next);
  }

  void _stepFps(int step) {
    if (!_playbackStarted || _completionDetected) return;
    final current = _fps ?? context.read<EncodeSettings>().fpsFor(_plan.size);
    final options = _fpsOptionsWith(current);
    final index = (options.indexOf(current) + step).clamp(
      0,
      options.length - 1,
    );
    setState(() => _fps = options[index]);
  }

  List<int> _fpsOptionsWith(int current) =>
      {..._fpsOptions, current}.toList()..sort();

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
      _ackArmed = false;
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

  /// [window] also puts the desktop window in full screen.
  void _enterFullscreen({bool window = true}) {
    setState(() => _fullscreenMode = true);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    if (window && isDesktopOS) _setWindowFullScreen(true);
  }

  void _exitFullscreen() {
    setState(() => _fullscreenMode = false);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (isDesktopOS) _setWindowFullScreen(false);
  }

  Future<void> _setWindowFullScreen(bool on) async {
    if (on) {
      if (_windowFullScreen || await windowManager.isFullScreen()) return;
      _windowFullScreen = true;
      await windowManager.setFullScreen(true);
    } else if (_windowFullScreen) {
      _windowFullScreen = false;
      await windowManager.setFullScreen(false);
    }
  }

  /// Leaving with the window's own controls also leaves the codes' full
  /// screen.
  @override
  void onWindowLeaveFullScreen() {
    if (!_windowFullScreen) return;
    _windowFullScreen = false;
    if (mounted && _fullscreenMode) _exitFullscreen();
  }

  /// Not using GestureDetector onDoubleTap because it would
  /// delay every single tap.
  void _onTapCodes() {
    final now = DateTime.now();
    final last = _lastTap;
    if (isDesktopOS &&
        last != null &&
        now.difference(last) < kDoubleTapTimeout) {
      _lastTap = null;
      if (_windowFullScreenBeforeTap) {
        if (_fullscreenMode) _exitFullscreen();
      } else {
        _enterFullscreen();
      }
      return;
    }
    _lastTap = now;
    _windowFullScreenBeforeTap = _windowFullScreen;
    _onToggleFill();
  }

  /// Codes fill the page, the window stays as it is.
  void _onToggleFill() {
    if (_fullscreenMode) {
      _exitFullscreen();
    } else {
      _enterFullscreen(window: false);
    }
  }

  void _onToggleFullscreen() {
    if (_windowFullScreen) {
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

  void _cleanup() {
    _listenerDelayTimer?.cancel();
    _acousticSub?.cancel();
    _acousticListener?.stop();
    _qrController.stopAnimation();
  }
}
