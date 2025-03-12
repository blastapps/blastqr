import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:blast_qr/widgets/raptorq_file_qr_widget.dart';
import 'package:flutter_avif/flutter_avif.dart';

class QrPage extends StatefulWidget {
  const QrPage({super.key, required this.file});

  final FileWrapper file;

  @override
  State<QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> {
  bool get _isLargeFile => widget.file.size > 1000000;
  bool _largeFileAcknowledged = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          FileHeaderWidget(file: widget.file),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: context.color.outline, width: 2),
              borderRadius: BorderRadius.circular(12),
              color:
                  _isLargeFile && !_largeFileAcknowledged
                      ? context.color.primaryContainer
                      : Colors.white,
            ),
            child:
                _isLargeFile && !_largeFileAcknowledged
                    ? FileTooLargeAlertWidget(
                      estimatedSlowestTime: widget.file.getEstimateTransferTime(
                        6,
                      ),
                      onAcknowledge: () {
                        setState(() {
                          _largeFileAcknowledged = true;
                        });
                      },
                    )
                    : RaptorFileQrWidget(file: widget.file),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Row(
                spacing: 8,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Text(context.l10n.done)],
              ),
            ),
          ),
        ],
      ),
    );
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
  const FileHeaderWidget({super.key, required this.file});

  final FileWrapper file;

  String get _estimatedTransferTime {
    final fast = file.getEstimateTransferTime(20);
    final slow = file.getEstimateTransferTime(6);
    return '${fast.toStringAsFixed(0)}~${slow.toStringAsFixed(0)}s';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 24),
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
                child: file.buildThumbnail(context),
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
              onPressed: () {
                Navigator.of(context).pop();
              },
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
  Widget buildThumbnail(BuildContext context) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    if (type.isAvifImage) {
      return AvifImage.file(
        file,
        fit: BoxFit.cover,
        cacheWidth: (72 * pixelRatio).toInt(),
      );
    } else if (type.isImage) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        cacheWidth: (72 * pixelRatio).toInt(),
      );
    }
    return Container(
      color: type.isAudio ? Colors.blueAccent : Colors.grey,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (type.isAudio) ...[
            Icon(Icons.audio_file, size: 64, color: Colors.white.withAlpha(80)),
          ] else ...[
            Icon(
              Icons.description,
              size: 64,
              color: Colors.white.withAlpha(80),
            ),
          ],
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
