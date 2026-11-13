import 'package:blast_qr/l10n/extension.dart';
import 'package:flutter/material.dart';

class FileTooLargeAlertWidget extends StatelessWidget {
  const FileTooLargeAlertWidget({
    super.key,
    required this.transferBytes,
    required this.isLongTransfer,
    required this.mayRunOutOfMemory,
    required this.onAcknowledge,
    required this.onCancel,
  });

  final int transferBytes;

  /// Says how long it could take.
  final bool isLongTransfer;

  /// Warns that the app could close for lack of memory.
  final bool mayRunOutOfMemory;

  final VoidCallback onCancel;
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
            Icon(mayRunOutOfMemory ? Icons.warning_amber : Icons.info_outline),
            Text(
              mayRunOutOfMemory
                  ? context.l10n.low_memory
                  : context.l10n.large_file,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        if (mayRunOutOfMemory)
          Text(
            context.l10n.low_memory_msg,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        if (isLongTransfer)
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
        if (mayRunOutOfMemory)
          ElevatedButton(onPressed: onCancel, child: Text(context.l10n.cancel)),
        OutlinedButton(
          onPressed: onAcknowledge,
          child: Text(context.l10n.send_large_file),
        ),
      ],
    );
  }
}
