import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/file_badge_count.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blast_qr/widgets/bottom_sheets.dart';
import 'package:blast_qr/widgets/file_preview.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';

/// Completes with true if the user discarded the files.
Future<bool?> showReceivedFilesSheet(
  BuildContext context, {
  required List<FileWrapper> files,
  required TextEditingController renameController,
  required double timeInSeconds,
  required int transferredBytes,
  bool encrypted = false,
}) {
  renameController.text = files.first.name;
  final speed = ((transferredBytes / 1000) / timeInSeconds).toStringAsFixed(1);
  return showSheet(
    context: context,
    title:
        '${context.l10n.received_in} ${timeInSeconds.toStringAsFixed(1)}s (${speed}kB/s)',
    body: _ReceivedFilesSheet(
      files: files,
      renameController: renameController,
      encrypted: encrypted,
    ),
  );
}

class _ReceivedFilesSheet extends StatelessWidget {
  const _ReceivedFilesSheet({
    required this.files,
    required this.renameController,
    required this.encrypted,
  });

  final List<FileWrapper> files;
  final TextEditingController renameController;
  final bool encrypted;

  void _open(BuildContext context, FileWrapper file) {
    try {
      OpenFile.open(file.file.path, type: file.type.mimeType ?? '');
    } catch (error) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString(), textAlign: TextAlign.center)),
      );
    }
  }

  Future<void> _discard(BuildContext context) async {
    final badgeCount = Provider.of<FileBadgeCount>(context, listen: false);
    for (final f in files) {
      badgeCount.subtract();
      await f.file.delete();
    }
    if (context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = files.first;
    return Column(
      children: [
        if (encrypted)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedSquareLock02,
                  size: 18,
                  color: context.color.onSurface,
                ),
                Text(context.l10n.received_encrypted),
              ],
            ),
          ),
        if (files.length > 1) ...[
          FilesPreview(files: files),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(context.l10n.files_count(files.length)),
          ),
        ] else ...[
          GestureDetector(
            onTap: () => _open(context, file),
            child: Container(
              width: 150,
              height: 150,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(60),
                    spreadRadius: 0,
                    blurRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
                borderRadius: BorderRadius.circular(12),
              ),
              child: file.buildThumbnail(context, size: 150),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: renameController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                suffixIcon: Padding(
                  padding: const EdgeInsetsGeometry.all(12),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedEdit01,
                    color: context.color.onSurface,
                  ),
                ),
                contentPadding: const EdgeInsetsDirectional.fromSTEB(
                  48,
                  0,
                  0,
                  8,
                ),
              ),
              onTap: () {
                final dotIndex = renameController.text.indexOf('.');
                renameController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: dotIndex > 0 ? dotIndex : 0,
                );
              },
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Row(
            spacing: 8,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _discard(context),
                  child: Text(context.l10n.discard),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(context.l10n.save),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
