import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/features/send/prepare_transfer.dart';
import 'package:blast_qr/features/send/rough_time.dart';
import 'package:blast_qr/features/send/widgets/raptorq_qr_streaming_widget.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blastqr_video/blastqr_video.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The size [files] are sent in and about how long that takes at the
/// current QR settings, updating with [hd].
class SendEstimate extends StatefulWidget {
  const SendEstimate({super.key, required this.files, required this.hd});

  final List<FileWrapper> files;

  /// On sends photos and videos as they are, off compresses them.
  final ValueListenable<bool> hd;

  @override
  State<SendEstimate> createState() => _SendEstimateState();
}

class _SendEstimateState extends State<SendEstimate> {
  /// Videos' durations, read without decoding them.
  final _videos = <String, VideoInfo>{};

  @override
  void initState() {
    super.initState();
    for (final file in widget.files.where(isCompressibleVideo)) {
      final path = file.file.path;
      BlastqrVideo.probe(path).then((info) {
        if (mounted) setState(() => _videos[path] = info);
      }, onError: (Object _) {});
    }
  }

  static String _kb(int bytes) => '${(bytes / 1000).toStringAsFixed(0)} KB';

  String _timeLabel(int seconds) => roughTime(
    seconds,
    inSeconds: context.l10n.send_time_seconds,
    inMinutes: context.l10n.send_time_minutes,
  );

  @override
  Widget build(BuildContext context) {
    final encode = Provider.of<EncodeSettings>(context);
    final codes = encode.multipleQrCodes
        ? RaptorQrStreamingWidget.maxCodesFor(MediaQuery.sizeOf(context))
        : 1;
    final style = TextStyle(color: context.color.secondary);
    return ValueListenableBuilder(
      valueListenable: widget.hd,
      builder: (context, hd, _) {
        final original = widget.files.fold(0, (sum, f) => sum + f.size);
        final estimate = estimateSendBytes(
          widget.files,
          compressMedia: !hd,
          videos: _videos,
        );
        // At best: every code shown is caught.
        final bytesPerSecond =
            encode.mtuFor(estimate) * encode.fpsFor(estimate) * codes;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (estimate < original)
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  Text(_kb(original), style: style),
                  Icon(Icons.arrow_forward, size: 14, color: style.color),
                  Text('~${_kb(estimate)}', style: style),
                ],
              )
            else
              Text(_kb(original), style: style),
            Text(
              _timeLabel((estimate / bytesPerSecond).ceil()),
              textAlign: TextAlign.center,
              style: style,
            ),
          ],
        );
      },
    );
  }
}
