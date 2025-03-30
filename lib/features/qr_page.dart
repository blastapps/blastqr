import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/features/help_page.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blast_qr/widgets/raptorq_qr_streaming_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

class QrPage extends StatefulWidget {
  const QrPage({super.key, required this.file});

  final FileWrapper file;

  @override
  State<QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> {
  final _qrController = RaptorQrStreamingWidgetController();
  bool get _isLargeFile => widget.file.size > 1000000;
  bool _largeFileAcknowledged = false;

  @override
  Widget build(BuildContext context) {
    final qrBoxHeight = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: context.color.primaryContainer,
      body: SafeArea(
        child: Column(
          children: [
            FileHeaderWidget(file: widget.file, onTapDismiss: _dismiss),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: context.color.outline, width: 2),
                    borderRadius: BorderRadius.circular(12),
                    color:
                        _isLargeFile && !_largeFileAcknowledged
                            ? context.color.primaryContainer
                            : Colors.white,
                  ),
                  child: SizedBox(
                    height: qrBoxHeight + 16,
                    child:
                        _isLargeFile && !_largeFileAcknowledged
                            ? FileTooLargeAlertWidget(
                              estimatedSlowestTime: widget.file
                                  .getEstimateTransferTime(8),
                              onAcknowledge: () {
                                setState(() {
                                  _largeFileAcknowledged = true;
                                });
                              },
                            )
                            : Consumer<EncodeSettings>(
                              builder: (context, state, child) {
                                return RaptorQrStreamingWidget(
                                  controller: _qrController,
                                  file: widget.file,
                                  mtu: state.mtu,
                                  compress: state.compress,
                                );
                              },
                            ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (context) => const HelpPage(),
                    ),
                  );
                },
                child: Row(
                  spacing: 8,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedInformationCircle,
                      color: context.color.onSurface,
                    ),
                    Expanded(child: Text(context.l10n.send_help_message)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
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

  void _dismiss() {
    _qrController.stopAnimation();
    Navigator.of(context).pop();
  }
}

class FileTooLargeAlertWidget extends StatelessWidget {
  const FileTooLargeAlertWidget({
    super.key,
    required this.onAcknowledge,
    required this.estimatedSlowestTime,
  });

  final Function() onAcknowledge;
  final double estimatedSlowestTime;

  String get estimateInMinutes =>
      (estimatedSlowestTime / 60).toStringAsFixed(0);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8,
        children: [
          Row(
            spacing: 4,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline),
              Text(
                context.l10n.large_file,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(text: context.l10n.large_file_msg_1),
                TextSpan(
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  text: ' $estimateInMinutes ${context.l10n.minutes} ',
                ),
                TextSpan(text: context.l10n.large_file_msg_2),
              ],
            ),
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: onAcknowledge,
            child: Text(context.l10n.continue_anyway),
          ),
        ],
      ),
    );
  }
}

class FileHeaderWidget extends StatelessWidget {
  const FileHeaderWidget({
    super.key,
    required this.file,
    required this.onTapDismiss,
  });

  final FileWrapper file;
  final void Function() onTapDismiss;

  String get _estimatedTransferTime {
    final fast = file.getEstimateTransferTime(40);
    final slow = file.getEstimateTransferTime(8);
    return '${fast.toStringAsFixed(0)}~${slow.toStringAsFixed(0)}s';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 16),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Container(
                width: 72,
                height: 72,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(60),
                      spreadRadius: 0,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: file.buildThumbnail(context, showsAvifThumbnail: true),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 36),
                      child: Text(
                        file.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                    Text(file.sizeInkB),
                    Text('$_estimatedTransferTime ${context.l10n.to_transfer}'),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: 36,
            width: 36,
            child: IconButton(
              onPressed: onTapDismiss,
              style: IconButton.styleFrom(
                backgroundColor: context.color.primaryContainer,
                foregroundColor: context.color.onSurface,
              ),
              padding: EdgeInsets.zero,
              icon: Icon(Icons.clear),
            ),
          ),
        ],
      ),
    );
  }
}

extension FileWrapperExtension on FileWrapper {
  Widget buildThumbnail(
    BuildContext context, {
    bool showsAvifThumbnail = false,
  }) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    if (type.isAvifImage && showsAvifThumbnail) {
      return AvifImage.file(
        file,
        fit: BoxFit.cover,
        cacheWidth: (72 * pixelRatio).toInt(),
      );
    } else if (type.isImage && !type.isAvifImage) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        cacheWidth: (72 * pixelRatio).toInt(),
      );
    }
    return Container(
      color: type.color,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(type.icon, size: 64, color: Colors.white.withAlpha(80)),
          FittedBox(
            child: Text(
              extension.toUpperCase(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

extension FileTypeExtension on FileType {
  IconData get icon {
    if (isImage) {
      return Icons.image;
    } else if (isVideo) {
      return Icons.video_file;
    } else if (isAudio) {
      return Icons.audio_file;
    }
    return Icons.description;
  }

  Color get color {
    if (isImage) {
      return Colors.deepOrangeAccent;
    } else if (isVideo) {
      return Colors.deepPurpleAccent;
    } else if (isAudio) {
      return Colors.blueAccent;
    }
    return Colors.grey;
  }
}
