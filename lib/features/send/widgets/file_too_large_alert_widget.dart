import 'package:blast_qr/features/settings/image_compression_settings_page.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class FileTooLargeAlertWidget extends StatefulWidget {
  const FileTooLargeAlertWidget({
    super.key,
    required this.transferBytes,
    required this.compressibleImages,
    required this.onAcknowledge,
    required this.onRequestCompressedImage,
  });

  final int transferBytes;

  /// How many images compressing would re-encode. With none, only sending
  /// as is is offered.
  final int compressibleImages;
  final VoidCallback onAcknowledge;
  final void Function(int quality) onRequestCompressedImage;

  @override
  State<FileTooLargeAlertWidget> createState() =>
      _FileTooLargeAlertWidgetState();
}

class _FileTooLargeAlertWidgetState extends State<FileTooLargeAlertWidget> {
  static const _slowestKBps = 8;

  String get _estimateInMinutes =>
      (widget.transferBytes / 1000 / _slowestKBps / 60).toStringAsFixed(0);

  final int _quality = 90;

  @override
  Widget build(BuildContext context) {
    // Centered when it fits, scrollable when the window is too short.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - 32).clamp(0, double.infinity),
          ),
          child: _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
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
                text: ' $_estimateInMinutes ${context.l10n.minutes} ',
              ),
              TextSpan(text: context.l10n.large_file_msg_2),
              if (widget.compressibleImages > 0)
                TextSpan(
                  text:
                      '\n${context.l10n.large_file_msg_3(widget.compressibleImages)}',
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (widget.compressibleImages > 0)
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
                  onPressed: _showImageCompressionSettings,
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
    );
  }

  void _showImageCompressionSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ImageCompressionSettingsPage(),
      ),
    );
  }
}
