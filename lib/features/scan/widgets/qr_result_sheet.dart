import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/file_badge_count.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/scanned_qr_code.dart';
import 'package:blast_qr/widgets/bottom_sheets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

Future<void> showQrResultSheet(BuildContext context, String content) {
  return showSheet(
    context: context,
    title: context.l10n.result,
    body: _QrResultSheet(content: content),
  );
}

class _QrResultSheet extends StatelessWidget {
  const _QrResultSheet({required this.content});

  final String content;

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.copied, textAlign: TextAlign.center)),
    );
  }

  Future<void> _save(BuildContext context) async {
    final navigator = Navigator.of(context);
    final badgeCount = Provider.of<FileBadgeCount>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await saveScannedQrCode(content, await qrCodesDirectory());
      badgeCount.add();
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(error.toString(), textAlign: TextAlign.center)),
      );
    }
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 4, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: context.color.surfaceContainer,
              border: Border.all(color: context.color.outline),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    content,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: context.l10n.copy,
                  onPressed: () => _copyToClipboard(context),
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedCopy01,
                    color: context.color.primary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _save(context),
            child: Text(context.l10n.save),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.dismiss),
          ),
        ],
      ),
    );
  }
}
