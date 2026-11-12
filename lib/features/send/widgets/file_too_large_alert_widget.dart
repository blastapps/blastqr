import 'package:blast_qr/l10n/extension.dart';
import 'package:flutter/material.dart';

class FileTooLargeAlertWidget extends StatelessWidget {
  const FileTooLargeAlertWidget({
    super.key,
    required this.transferBytes,
    required this.onAcknowledge,
  });

  final int transferBytes;
  final VoidCallback onAcknowledge;

  static const _slowestKBps = 24;

  String get _estimateInMinutes =>
      (transferBytes / 1000 / _slowestKBps / 60).toStringAsFixed(0);

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
            ],
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: onAcknowledge,
          child: Text(context.l10n.send_large_file),
        ),
      ],
    );
  }
}
