import 'dart:developer';
import 'dart:io';

import 'package:blast_qr/color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:blast_qr/widgets/raptorq_file_qr_widget.dart';

class QrPage extends StatefulWidget {
  const QrPage({super.key, required this.file, required this.fileSizeInBytes});

  final File file;
  final int fileSizeInBytes;

  @override
  State<QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> {
  bool get _isLargeFile => widget.fileSizeInBytes > 1000000;
  bool _largeFileAcknowledged = false;

  double get _estimatedFastestTime => (widget.fileSizeInBytes / 1000) / 20;
  double get _estimatedSlowestTime => (widget.fileSizeInBytes / 1000) / 6;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          FileHeaderWidget(
            file: widget.file,
            fileSizeInBytes: widget.fileSizeInBytes,
            estimatedFastestTime: _estimatedFastestTime,
            estimatedSlowestTime: _estimatedSlowestTime,
          ),
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
                      estimatedSlowestTime: _estimatedSlowestTime,
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
                children: [Text('Done')],
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
                'Large file',
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
                TextSpan(
                  text: 'The file you selected is large and could take up to ',
                ),
                TextSpan(
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  text: '$estimateInMinutes minutes ',
                ),
                TextSpan(text: 'to transfer.'),
              ],
            ),
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: onAcknowledge,
            child: Text('Continue anyway'),
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
    required this.fileSizeInBytes,
    required this.estimatedFastestTime,
    required this.estimatedSlowestTime,
  });

  final File file;
  final int fileSizeInBytes;
  final double estimatedFastestTime;
  final double estimatedSlowestTime;

  String get fileName => file.uri.pathSegments.last;

  String get fileSize => '${(fileSizeInBytes / 1000).toStringAsFixed(0)} KB';

  String get _estimatedTransferTime {
    return '${estimatedFastestTime.toStringAsFixed(0)}~${estimatedSlowestTime.toStringAsFixed(0)}s to transfer';
  }

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
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
                child: Image.file(
                  file,
                  fit: BoxFit.cover,
                  cacheWidth: (72 * pixelRatio).toInt(),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 36),
                      child: Text(
                        fileName,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                    Text(fileSize),
                    Text(_estimatedTransferTime),
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
                log('pressed');
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
