import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/features/send/prepare_transfer.dart';
import 'package:blast_qr/features/send/qr_page.dart';
import 'package:blast_qr/features/send/send_options.dart';
import 'package:blast_qr/features/send/widgets/preparing_sheet.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/blast_qrcode_data.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Prepares [files] for sending with [options] (see [prepareTransfer]) and
/// shows the QR page for them. Completes when the QR page is closed.
Future<void> sendFiles(
  BuildContext context,
  List<FileWrapper> files,
  SendOptions options,
) async {
  // Another app may have deleted or moved it since it was listed.
  final exists = await Future.wait(files.map((f) => f.file.exists()));
  if (!context.mounted) return;
  final missing = exists.indexOf(false);
  if (missing != -1) {
    await showFileMissing(context, files[missing].name);
    return;
  }
  // Checked again once prepared, when the real size is known.
  final tooLarge = transferTooLargeMessage(context, minSendBytes(files));
  if (tooLarge != null) {
    await showFileTooLarge(context, tooLarge);
    return;
  }

  final imageSettings = Provider.of<AppSettings>(
    context,
    listen: false,
  ).imageCompressionSettings;
  final transfer = await runWithPreparingSheet(
    context,
    videoCount: options.compressMedia
        ? files.where(isCompressibleVideo).length
        : 0,
    prepare: (onProgress, cancel) => prepareTransfer(
      files,
      options,
      imageSettings: imageSettings,
      onProgress: onProgress,
      cancel: cancel,
    ),
  );
  if (transfer == null || !context.mounted) return;
  final transferTooLarge = transferTooLargeMessage(
    context,
    transfer.bytes.length,
  );
  if (transferTooLarge != null) {
    await showFileTooLarge(context, transferTooLarge);
    return;
  }

  await Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => QrPage(transfer: transfer),
    ),
  );
}

/// The reason [size] bytes can't be sent with the current QR code size, if
/// any.
String? transferTooLargeMessage(BuildContext context, int size) {
  if (size > BlastQrcodeData.maxFileBytes) {
    return context.l10n.file_too_large_msg;
  }
  final mtu = Provider.of<EncodeSettings>(context, listen: false).mtu;
  final symbolSize = BlastQrcodeData.symbolSizeForMtu(mtu);
  final transferLength = size + BlastQrcodeData.maxMetadataBytes;
  if (!BlastQrcodeData.fitsSymbolLimit(transferLength, symbolSize)) {
    return context.l10n.file_too_large_for_qr_size_msg;
  }
  return null;
}

Future<void> showFileTooLarge(BuildContext context, String message) =>
    _showAlert(context, context.l10n.file_too_large, message);

Future<void> showFileMissing(BuildContext context, String name) => _showAlert(
  context,
  context.l10n.file_missing,
  context.l10n.file_missing_msg(name),
);

Future<void> _showAlert(BuildContext context, String title, String message) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.ok),
        ),
      ],
    ),
  );
}
