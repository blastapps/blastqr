import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/scanned_qr_code.dart';
import 'package:blast_qr/widgets/bottom_sheets.dart';
import 'package:blast_qr/widgets/qr_code_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

Future<void> showQrCodeSheet(
  BuildContext context,
  ScannedQrCode code, {
  required VoidCallback onDelete,
}) {
  return showSheet(
    context: context,
    title: context.l10n.qr_code,
    body: Column(
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(60),
                blurRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
            borderRadius: BorderRadius.circular(4),
          ),
          child: QrCodeThumbnail(text: code.text, size: 150),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: SelectableText(
              code.text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        ListTile(
          dense: true,
          onTap: () {
            Navigator.of(context).pop();
            Clipboard.setData(ClipboardData(text: code.text));
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(context.l10n.copied)));
          },
          leading: HugeIcon(
            icon: HugeIcons.strokeRoundedCopy01,
            color: context.color.primary,
          ),
          title: Text(context.l10n.copy),
        ),
        ListTile(
          dense: true,
          onTap: onDelete,
          leading: HugeIcon(
            icon: HugeIcons.strokeRoundedDelete01,
            color: context.color.primary,
          ),
          title: Text(context.l10n.delete),
        ),
        const SizedBox(height: 8),
      ],
    ),
  );
}
