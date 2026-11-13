import 'dart:async';

import 'package:blast_qr/acoustic_ack_listener.dart';
import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/features/help/help_page.dart';
import 'package:blast_qr/features/send/prepare_transfer.dart';
import 'package:blast_qr/features/send/widgets/acoustic_success_overlay.dart';
import 'package:blast_qr/features/send/widgets/file_header_widget.dart';
import 'package:blast_qr/features/send/widgets/file_too_large_alert_widget.dart';
import 'package:blast_qr/features/send/widgets/raptorq_qr_streaming_widget.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/platform_support.dart';
import 'package:blast_qr/widgets/bottom_sheets.dart';
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

/// Shows [transfer] as QR codes, after a prompt if it's large.
class QrPage extends StatefulWidget {
  const QrPage({
    super.key,
    required this.transfer,
    this.mayRunOutOfMemory = false,
  });

  final PreparedTransfer transfer;

  /// Whether to warn that the app could close for lack of memory.
  final bool mayRunOutOfMemory;

  @override
  State<QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> with WindowListener {
  final _qrController = RaptorQrStreamingWidgetController();
  final _qrBoxKey = GlobalKey();

  /// Whether the user chose to send a large transfer anyway.
  bool _acknowledged = false;

  static const _fpsOptions = [15, 20, 25, 30, 60];

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

  /// Detections only count from here: the receiver can't have the file
  /// before every source code was shown.
  bool _nearlyComplete = false;
  bool _completionDetected = false;
  bool _dismissed = false;

  /// Whether enough codes were shown for the receiver to have the file, if
  /// it caught them all.
  bool _sourceShown = false;

  /// Closing now would leave the receiver without the file.
  bool get _closingStopsSend =>
      _playbackStarted && !_sourceShown && !_completionDetected;

  int get _size => widget.transfer.length;

  String? get _password => widget.transfer.password;

  /// Compressed transfers skip it: the user already made them as small as
  /// they can be.
  bool get _isLongTransfer =>
      !widget.transfer.compressed && _size > largeTransferBytes;

  bool get _showsWarning =>
      !_acknowledged && (_isLongTransfer || widget.mayRunOutOfMemory);

  bool get _showsPasswordButton =>
      !_fullscreenMode && _password != null && !_completionDetected;

  @override
  void initState() {
    super.initState();
    if (isDesktopOS) windowManager.addListener(this);
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    if (isDesktopOS) {
      windowManager.removeListener(this);
      if (_windowFullScreen) windowManager.setFullScreen(false);
    }
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
    return PopScope(
      canPop: !_closingStopsSend,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _dismiss();
      },
      child: _buildPage(context, qrBox),
    );
  }

  Widget _buildPage(BuildContext context, Widget qrBox) {
    return Scaffold(
      backgroundColor: context.color.primaryContainer,
      body: SafeArea(
        child: _fullscreenMode
            ? qrBox
            : Column(
                children: [
                  FileHeaderWidget(
                    files: widget.transfer.files,
                    name: widget.transfer.isBundle
                        ? null
                        : widget.transfer.name,
                    onTapDismiss: _dismiss,
                    compressedSize: _size,
                    encrypted: _password != null,
                  ),
                  // The QR box takes what the controls leave, so both stay
                  // visible however wide or short the window is.
                  Expanded(
                    child: Column(
                      children: [
                        Flexible(child: qrBox),
                        // Space is kept while the codes are generated, so the
                        // QR box doesn't shrink when playback starts.
                        if (!_completionDetected && !_showsWarning)
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
    return Stack(
      key: _qrBoxKey,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: context.color.outline, width: 2),
            color: _showsWarning
                ? context.color.primaryContainer
                : Colors.white,
          ),
          child: _showsWarning
              ? FileTooLargeAlertWidget(
                  transferBytes: _size,
                  isLongTransfer: _isLongTransfer,
                  mayRunOutOfMemory: widget.mayRunOutOfMemory,
                  onAcknowledge: () => setState(() => _acknowledged = true),
                  onCancel: () => Navigator.of(context).pop(),
                )
              : Consumer<EncodeSettings>(
                  builder: (context, state, child) {
                    final mtu = state.mtuFor(_size);
                    final fps = _fps ?? state.fpsFor(_size);
                    return RaptorQrStreamingWidget(
                      controller: _qrController,
                      transfer: widget.transfer,
                      mtu: mtu,
                      fps: fps,
                      fill: _fullscreenMode,
                      onTap: _onTapCodes,
                      onNearlyComplete: () => _nearlyComplete = true,
                      onSourceShown: () => _sourceShown = true,
                      onStart: () =>
                          _onStart(multipleQrCodes: state.multipleQrCodes),
                    );
                  },
                ),
        ),
        if (_completionDetected)
          Positioned.fill(
            child: AcousticSuccessOverlay(
              onKeepShowing: _onKeepShowingQr,
              onDone: _dismiss,
              password: _password,
            ),
          ),
      ],
    );
  }

  Widget _buildControls(BuildContext context) {
    final encodeSettings = Provider.of<EncodeSettings>(context);
    final fps = _fps ?? encodeSettings.fpsFor(_size);
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
              child: PasswordButton(password: _password!),
            ),
        ],
      ),
    );
  }

  void _onStart({required bool multipleQrCodes}) {
    setState(() => _playbackStarted = true);
    if (multipleQrCodes) _enterFullscreen();
    _startAcousticListener();
  }

  /// Starts the mic right away, because starting it blocks the main thread
  /// and would stutter the animation if done mid-transfer.
  void _startAcousticListener() {
    final appSettings = Provider.of<AppSettings>(context, listen: false);
    if (!appSettings.acousticDetection) return;

    if (_acousticListener == null) {
      _acousticListener = AcousticAckListener();
      _acousticSub = _acousticListener!.onDetected.listen((_) {
        if (!mounted || !_nearlyComplete || _completionDetected) return;
        if (_fullscreenMode) _exitFullscreen();
        setState(() => _completionDetected = true);
      });
    }
    _acousticListener!.start();
  }

  void _cycleFps(int current) {
    final options = _fpsOptionsWith(current);
    final next = options[(options.indexOf(current) + 1) % options.length];
    setState(() => _fps = next);
  }

  void _stepFps(int step) {
    if (!_playbackStarted || _completionDetected) return;
    final current = _fps ?? context.read<EncodeSettings>().fpsFor(_size);
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
    _startAcousticListener();
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

  Future<void> _dismiss() async {
    if (_dismissed) return;
    if (_closingStopsSend && !await _confirmStop()) return;
    if (!mounted || _dismissed) return;
    _dismissed = true;
    _cleanup();
    Navigator.of(context).pop();
  }

  Future<bool> _confirmStop() async {
    var stop = false;
    await showMessage(
      context: context,
      title: context.l10n.stop_sending,
      message: context.l10n.stop_sending_msg,
      confirmTitle: context.l10n.stop,
      secondaryTitle: context.l10n.keep_sending,
      onConfirmTap: () => stop = true,
    );
    return stop;
  }

  void _cleanup() {
    _acousticSub?.cancel();
    _acousticListener?.stop();
    _qrController.stopAnimation();
  }
}
