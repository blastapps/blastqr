import 'dart:async';

import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/features/send/rough_time.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/widgets/bottom_sheets.dart';
import 'package:flutter/material.dart';

/// Runs [prepare], showing a sheet with its progress if it takes more than
/// a moment. Closing the sheet completes the cancel future [prepare] gets,
/// and makes this return null even if [prepare] can't stop.
///
/// With [videoCount] videos to compress, the sheet shows their progress as
/// reported by [prepare], and the time left.
Future<T?> runWithPreparingSheet<T>(
  BuildContext context, {
  required int videoCount,
  required Future<T> Function(
    void Function(double progress) onProgress,
    Future<void> cancel,
  )
  prepare,
}) async {
  final cancel = Completer<void>();
  final progress = ValueNotifier<double>(0);
  var done = false;
  var sheetOpen = false;
  BuildContext? sheetContext;
  // Most sends are ready right away, without a sheet flashing by.
  final timer = Timer(const Duration(milliseconds: 200), () {
    if (done || !context.mounted) return;
    sheetOpen = true;
    showSheet<void>(
      context: context,
      title: context.l10n.preparing_transfer,
      body: Builder(
        builder: (context) {
          sheetContext = context;
          return _PreparingBody(
            progress: progress,
            videoCount: videoCount,
            onCancel: () => Navigator.of(context).pop(),
          );
        },
      ),
    ).whenComplete(() {
      sheetOpen = false;
      if (!done && !cancel.isCompleted) cancel.complete();
    });
  });
  try {
    final result = await prepare((p) => progress.value = p, cancel.future);
    return cancel.isCompleted ? null : result;
  } on Object catch (e) {
    if (!cancel.isCompleted) debugPrint('Preparing failed: $e');
    return null;
  } finally {
    done = true;
    timer.cancel();
    final sheet = sheetContext;
    // Only while it's on top: popping otherwise closes the page below.
    if (sheetOpen &&
        sheet != null &&
        sheet.mounted &&
        (ModalRoute.of(sheet)?.isCurrent ?? false)) {
      Navigator.of(sheet).pop();
    }
  }
}

class _PreparingBody extends StatefulWidget {
  const _PreparingBody({
    required this.progress,
    required this.videoCount,
    required this.onCancel,
  });

  final ValueNotifier<double> progress;
  final int videoCount;
  final VoidCallback onCancel;

  @override
  State<_PreparingBody> createState() => _PreparingBodyState();
}

class _PreparingBodyState extends State<_PreparingBody> {
  /// Early progress includes setting up the encoder, so it says little
  /// about the rest.
  static const _minElapsed = Duration(seconds: 3);
  static const _minProgress = 0.02;

  final _stopwatch = Stopwatch()..start();

  String _status(double progress) {
    final elapsed = _stopwatch.elapsed;
    if (elapsed < _minElapsed || progress < _minProgress) {
      return '${(progress * 100).floor()}%';
    }
    return roughTime(
      (elapsed * ((1 - progress) / progress)).inSeconds,
      inSeconds: context.l10n.time_left_seconds,
      inMinutes: context.l10n.time_left_minutes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: SizedBox(
        width: double.infinity,
        child: widget.videoCount == 0
            ? const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Center(child: CircularProgressIndicator.adaptive()),
              )
            : ValueListenableBuilder(
                valueListenable: widget.progress,
                builder: (context, progress, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 12,
                  children: [
                    Text(
                      context.l10n.compressing_videos(widget.videoCount),
                      style: textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    LinearProgressIndicator(
                      value: progress > 0 ? progress : null,
                      color: context.color.primary,
                      backgroundColor: context.color.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 6,
                    ),
                    Text(_status(progress), style: textTheme.bodyMedium),
                    OutlinedButton(
                      onPressed: widget.onCancel,
                      child: Text(context.l10n.cancel),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
