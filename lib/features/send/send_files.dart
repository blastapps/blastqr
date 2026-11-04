import 'dart:io';

import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/file_bundle.dart';
import 'package:blast_qr/features/send/helpers/file_qr_encoder.dart';
import 'package:blast_qr/features/send/qr_page.dart';
import 'package:blast_qr/features/send/send_plan.dart';
import 'package:blast_qr/features/send/send_options.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/blast_qrcode_data.dart';
import 'package:blast_qr/model/file_extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blast_qr/model/image_compression_settings.dart';
import 'package:blast_qr/temp_files.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Shows the QR page for [files]. Several files are sent as one bundle,
/// which the QR page builds. Completes when the QR page is closed.
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
  // Compressing images can bring a bundle under the limit, so such a bundle
  // is only checked once built.
  if (files.length == 1 || !files.any(isCompressibleInBundle)) {
    final size = files.fold(0, (sum, f) => sum + f.size);
    final tooLarge = transferTooLargeMessage(context, size);
    if (tooLarge != null) {
      await showFileTooLarge(context, tooLarge);
      return;
    }
  }
  await Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => QrPage(
        files: files,
        password: options.password,
        fileName: options.fileName,
      ),
    ),
  );
}

/// Zips [files] into a temporary file. Large images are re-encoded first
/// when [icSettings] is given, as for a single file.
Future<FileWrapper> createSendBundle(
  List<FileWrapper> files, {
  ImageCompressionSettings? icSettings,
}) async {
  final entries = <BundleEntry>[];
  for (final file in files) {
    if (icSettings != null && isCompressibleInBundle(file)) {
      final bytes = await FileQrEncoder.compressImage(
        await file.file.readAsBytes(),
        icSettings,
      );
      if (bytes != null) {
        final extension =
            icSettings.outputFormat.extension ?? file.type.extension;
        entries.add((
          name: '${file.nameWithoutExtension}.$extension',
          path: null,
          bytes: bytes,
        ));
        continue;
      }
    }
    entries.add((name: file.name, path: file.file.path, bytes: null));
  }

  final directory = Directory('${(await appTempDirectory()).path}/bundles');
  await directory.create(recursive: true);
  final timestamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
  final path = '${directory.path}/blastqr-$timestamp.zip';
  await writeBundle(entries, path);
  return File(path).toFileWrapper();
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
