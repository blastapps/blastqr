import 'dart:io';

import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/features/send/prepare_transfer.dart';
import 'package:blast_qr/features/send/send_options.dart';
import 'package:blast_qr/features/send/widgets/custom_password_sheet.dart';
import 'package:blast_qr/features/send/widgets/hd_toggle.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blast_qr/widgets/bottom_sheets.dart';
import 'package:blast_qr/widgets/centered_with_trailing.dart';
import 'package:blast_qr/widgets/file_preview.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// The sheet that opens when tapping a received file. Send closes the sheet
/// itself; the other callbacks decide when to close it.
Future<void> showFileOptionsSheet(
  BuildContext context,
  FileWrapper file, {
  required VoidCallback onOpen,
  void Function(Rect origin)? onShare,
  VoidCallback? onShowInFileManager,
  VoidCallback? onSave,
  required VoidCallback onRename,
  required void Function(SendOptions options) onSend,
  required VoidCallback onDelete,
}) {
  final hd = ValueNotifier(
    !Provider.of<AppSettings>(context, listen: false).compressMediaByDefault,
  );
  return showSheet(
    context: context,
    title: context.l10n.file_options,
    body: Column(
      children: [
        _FilePreview(
          file: file,
          detail: DateFormat('yyyy-MM-dd HH:mm:ss').format(file.modified),
          onTapThumbnail: onOpen,
          thumbnailTrailing: isCompressibleMedia(file)
              ? HdToggle(hd: hd)
              : null,
        ),
        const SizedBox(height: 8),
        SendTile(
          onTap: () {
            Navigator.of(context).pop();
            onSend(plainSend(compressMedia: !hd.value));
          },
        ),
        SendEncryptedTile(
          onTap: () {
            Navigator.of(context).pop();
            onSend(encryptedSend(compressMedia: !hd.value));
          },
          onLongPress: () async {
            Navigator.of(context).pop();
            final password = await showCustomPasswordSheet(context);
            if (password == null || !context.mounted) return;
            onSend((
              password: password,
              fileName: null,
              compressMedia: !hd.value,
            ));
          },
        ),
        const DottedDivider(),
        ListTile(
          onTap: onOpen,
          leading: HugeIcon(
            icon: HugeIcons.strokeRoundedPackageOpen,
            color: context.color.primary,
          ),
          title: Text(context.l10n.open),
        ),
        if (onShare != null)
          Builder(
            builder: (tileContext) => ListTile(
              onTap: () {
                final box = tileContext.findRenderObject() as RenderBox;
                onShare(box.localToGlobal(Offset.zero) & box.size);
              },
              leading: HugeIcon(
                icon: HugeIcons.strokeRoundedShare08,
                color: context.color.primary,
              ),
              title: Text(context.l10n.share),
            ),
          ),
        if (onShowInFileManager != null)
          ListTile(
            onTap: onShowInFileManager,
            leading: HugeIcon(
              icon: HugeIcons.strokeRoundedFolderOpen,
              color: context.color.primary,
            ),
            title: Text(context.l10n.show_in_file_manager),
          ),
        if (onSave != null)
          ListTile(
            onTap: onSave,
            leading: HugeIcon(
              icon: Platform.isIOS
                  ? HugeIcons.strokeRoundedFolderAdd
                  : HugeIcons.strokeRoundedDownload01,
              color: context.color.primary,
            ),
            title: Text(
              Platform.isIOS
                  ? context.l10n.save_to_files
                  : context.l10n.save_to_downloads,
            ),
          ),
        ListTile(
          onTap: onRename,
          leading: HugeIcon(
            icon: HugeIcons.strokeRoundedEdit01,
            color: context.color.primary,
          ),
          title: Text(context.l10n.rename),
        ),
        ListTile(
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

class _FilePreview extends StatelessWidget {
  const _FilePreview({
    required this.file,
    required this.detail,
    this.onTapThumbnail,
    this.thumbnailTrailing,
  });

  final FileWrapper file;
  final String detail;
  final VoidCallback? onTapThumbnail;
  final Widget? thumbnailTrailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CenteredWithTrailing(
          trailing: thumbnailTrailing,
          child: GestureDetector(
            onTap: onTapThumbnail,
            child: FileThumbnail(file: file, size: 92),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(file.name, textAlign: TextAlign.center),
        ),
        const SizedBox(height: 4),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.color.secondary),
        ),
      ],
    );
  }
}

class DottedDivider extends StatelessWidget {
  const DottedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 16,
        width: double.infinity,
        child: CustomPaint(
          painter: _DottedLinePainter(color: Theme.of(context).dividerColor),
        ),
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  const _DottedLinePainter({required this.color});

  final Color color;

  static const _radius = 1.0;
  static const _spacing = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final y = size.height / 2;
    for (var x = _radius; x < size.width; x += _spacing) {
      canvas.drawCircle(Offset(x, y), _radius, paint);
    }
  }

  @override
  bool shouldRepaint(_DottedLinePainter old) => old.color != color;
}
