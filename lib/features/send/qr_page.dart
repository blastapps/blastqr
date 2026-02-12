import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/features/help/help_page.dart';
import 'package:blast_qr/features/send/widgets/raptorq_qr_streaming_widget.dart';
import 'package:blast_qr/features/settings/image_compression_settings_page.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/file_type.dart';
import 'package:blast_qr/model/file_wrapper.dart';
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
  bool get _isLargeFile => widget.file.size > 185000;
  bool _largeFileAcknowledged = false;
  bool _shouldCompressImage = false;

  bool _fullscreenMode = false;

  @override
  Widget build(BuildContext context) {
    final qrBoxHeight = MediaQuery.of(context).size.width;
    final appSettings = Provider.of<AppSettings>(context, listen: false);

    return Scaffold(
      backgroundColor: context.color.primaryContainer,
      body: SafeArea(
        child: Column(
          children: [
            if (!_fullscreenMode)
              FileHeaderWidget(file: widget.file, onTapDismiss: _dismiss),
            Expanded(
              key: const ValueKey('qr_container'),
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
                    height: _fullscreenMode ? null : qrBoxHeight + 16,
                    child:
                        _isLargeFile && !_largeFileAcknowledged
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
                                  imageCompressionSettings:
                                      _shouldCompressImage
                                          ? appSettings.imageCompressionSettings
                                          : null,
                                  fill: _fullscreenMode,
                                  onTap: () {
                                    setState(() {
                                      _fullscreenMode = !_fullscreenMode;
                                    });
                                  },
                                );
                              },
                            ),
                  ),
                ),
              ),
            ),
            if (!_fullscreenMode && (!_isLargeFile || _largeFileAcknowledged))
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
            if (!_fullscreenMode)
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

class FileTooLargeAlertWidget extends StatefulWidget {
  const FileTooLargeAlertWidget({
    super.key,
    required this.estimatedSlowestTime,
    required this.fileType,
    required this.onAcknowledge,
    required this.onRequestCompressedImage,
  });

  final double estimatedSlowestTime;
  final FileType fileType;
  final Function() onAcknowledge;
  final Function(int quality) onRequestCompressedImage;

  @override
  State<FileTooLargeAlertWidget> createState() =>
      _FileTooLargeAlertWidgetState();
}

class _FileTooLargeAlertWidgetState extends State<FileTooLargeAlertWidget> {
  String get estimateInMinutes =>
      (widget.estimatedSlowestTime / 60).toStringAsFixed(0);

  final int _quality = 90;

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
              const Icon(Icons.info_outline),
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
                if (widget.fileType.allowsImageCompression)
                  TextSpan(text: '\n${context.l10n.large_file_msg_3}'),
              ],
            ),
          ),

          const SizedBox(height: 8),
          if (widget.fileType.allowsImageCompression)
            Row(
              spacing: 4,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => widget.onRequestCompressedImage(_quality),
                    child: Text(context.l10n.send_compressed_image),
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => _showImageCompressionSettings(),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedSettings01,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          OutlinedButton(
            onPressed: widget.onAcknowledge,
            child: Text(context.l10n.send_large_file),
          ),
        ],
      ),
    );
  }

  void _showImageCompressionSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return const ImageCompressionSettingsPage();
        },
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
                      offset: const Offset(0, 2),
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
              icon: const Icon(Icons.clear),
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
              style: const TextStyle(
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
