import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/features/files_received/received_items.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blast_qr/widgets/qr_code_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReceivedItemTile extends StatelessWidget {
  const ReceivedItemTile({
    super.key,
    required this.item,
    required this.isSelecting,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  static const _thumbnailSize = 56.0;

  final ReceivedItem item;
  final bool isSelecting;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final (thumbnail, title, subtitle) = switch (item) {
      ReceivedFile(:final file) => (
        file.buildThumbnail(context, size: _thumbnailSize),
        file.name,
        file.sizeInkB,
      ),
      ReceivedQrCode(:final code) => (
        QrCodeThumbnail(text: code.text, size: _thumbnailSize),
        context.l10n.scanned_at(
          DateFormat.yMd(
            Localizations.localeOf(context).languageCode,
          ).add_Hm().format(code.scanned),
        ),
        code.sizeLabel,
      ),
    };
    return ListTile(
      selected: isSelecting && isSelected,
      onTap: onTap,
      onLongPress: onLongPress,
      leading: Stack(
        children: [
          Container(
            width: _thumbnailSize,
            height: _thumbnailSize,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(60),
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
              borderRadius: BorderRadius.circular(4),
            ),
            child: thumbnail,
          ),
          if (isSelecting)
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.color.primary.withAlpha(180)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 28)
                    : null,
              ),
            ),
        ],
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle),
    );
  }
}
