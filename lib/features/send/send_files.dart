import 'dart:io';

import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/file_bundle.dart';
import 'package:blast_qr/features/send/helpers/file_qr_encoder.dart';
import 'package:blast_qr/features/send/qr_page.dart';
import 'package:blast_qr/features/send/send_options.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/blast_qrcode_data.dart';
import 'package:blast_qr/model/file_extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blast_qr/model/image_compression_settings.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

/// Shows the QR page for [files]. Several files are sent as one bundle.
/// Completes when the QR page is closed.
Future<void> sendFiles(
  BuildContext context,
  List<FileWrapper> files,
  SendOptions options,
) async {
  if (files.length == 1) {
    final tooLarge = transferTooLargeMessage(context, files.single);
    if (tooLarge != null) {
      await showFileTooLarge(context, tooLarge);
      return;
    }
    await _showQrPage(context, files.single, options);
    return;
  }

  final appSettings = Provider.of<AppSettings>(context, listen: false);
  final bundle = await _withProgress(
    context,
    createSendBundle(
      files,
      icSettings:
          appSettings.alwaysCompressImages
              ? appSettings.imageCompressionSettings
              : null,
    ),
  );
  try {
    if (!context.mounted) return;
    final tooLarge = transferTooLargeMessage(context, bundle);
    if (tooLarge != null) {
      await showFileTooLarge(context, tooLarge);
      return;
    }
    await _showQrPage(context, bundle, options, bundledFiles: files);
  } finally {
    await bundle.file.delete();
  }
}

/// Zips [files] into a temporary file. Large images are re-encoded first
/// when [icSettings] is given, as for a single file.
Future<FileWrapper> createSendBundle(
  List<FileWrapper> files, {
  ImageCompressionSettings? icSettings,
}) async {
  final entries = <BundleEntry>[];
  for (final file in files) {
    if (icSettings != null &&
        file.type.allowsImageCompression &&
        file.size > QrPage.largeFileBytes) {
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

  final directory = Directory('${(await getTemporaryDirectory()).path}/bundles');
  await directory.create(recursive: true);
  final timestamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
  final path = '${directory.path}/blastqr-$timestamp.zip';
  await writeBundle(entries, path);
  return File(path).toFileWrapper();
}

/// The reason [file] can't be sent with the current QR code size, if any.
String? transferTooLargeMessage(BuildContext context, FileWrapper file) {
  if (file.size > BlastQrcodeData.maxFileBytes) {
    return context.l10n.file_too_large_msg;
  }
  final mtu = Provider.of<EncodeSettings>(context, listen: false).mtu;
  final symbolSize = BlastQrcodeData.symbolSizeForMtu(mtu);
  final transferLength = file.size + BlastQrcodeData.maxMetadataBytes;
  if (!BlastQrcodeData.fitsSymbolLimit(transferLength, symbolSize)) {
    return context.l10n.file_too_large_for_qr_size_msg;
  }
  return null;
}

Future<void> showFileTooLarge(BuildContext context, String message) {
  return showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Text(context.l10n.file_too_large),
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

Future<void> _showQrPage(
  BuildContext context,
  FileWrapper file,
  SendOptions options, {
  List<FileWrapper> bundledFiles = const [],
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder:
          (context) => QrPage(
            file: file,
            bundledFiles: bundledFiles,
            password: options.password,
            fileName: options.fileName,
          ),
    ),
  );
}

Future<T> _withProgress<T>(BuildContext context, Future<T> future) async {
  final navigator = Navigator.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder:
        (context) => const PopScope(
          canPop: false,
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
  );
  try {
    return await future;
  } finally {
    navigator.pop();
  }
}
