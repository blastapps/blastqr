import 'package:blast_qr/color_scheme.dart';
import 'package:flutter/material.dart';

/// A phone list tile for a file: a thumbnail that shows a checkmark when
/// selected, a title and a subtitle.
class FileListTile extends StatelessWidget {
  const FileListTile({
    super.key,
    required this.thumbnail,
    required this.title,
    required this.subtitle,
    required this.isSelecting,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  /// Size for [thumbnail].
  static const thumbnailSize = 56.0;

  final Widget thumbnail;
  final String title;
  final String subtitle;
  final bool isSelecting;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: isSelecting && isSelected,
      onTap: onTap,
      onLongPress: onLongPress,
      leading: Stack(
        children: [
          Container(
            width: thumbnailSize,
            height: thumbnailSize,
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
