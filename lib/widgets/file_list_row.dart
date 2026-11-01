import 'package:blast_qr/color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A compact desktop row: icon, name, date and size, like a file manager's
/// list view.
class FileListRow extends StatelessWidget {
  const FileListRow({
    super.key,
    required this.thumbnail,
    required this.name,
    this.date,
    required this.size,
    required this.striped,
    required this.selected,
    required this.showCheckmark,
    required this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.margin = const EdgeInsets.symmetric(horizontal: 8),
  });

  /// Size for [thumbnail].
  static const iconSize = 22.0;
  static const _dateWidth = 170.0;
  static const _sizeWidth = 72.0;

  /// The date column only shows when this much is left for the name.
  static const _minNameWidth = 200.0;
  static const _radius = BorderRadius.all(Radius.circular(6));

  final Widget thumbnail;
  final String name;

  /// Leaves out the date column when null.
  final DateTime? date;
  final String size;
  final bool striped;
  final bool selected;
  final bool showCheckmark;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final textColor = selected ? context.color.onPrimary : null;
    final secondaryColor = selected
        ? context.color.onPrimary.withValues(alpha: 0.85)
        : context.color.onSurfaceVariant;
    final secondaryStyle = TextStyle(fontSize: 13, color: secondaryColor);
    return Padding(
      padding: margin,
      child: GestureDetector(
        onSecondaryTap: onSecondaryTap,
        child: Material(
          color: selected
              ? context.color.primary
              : striped
              ? context.color.onSurface.withValues(alpha: 0.04)
              : Colors.transparent,
          borderRadius: _radius,
          child: InkWell(
            borderRadius: _radius,
            // Lists of these rows are one focus stop, the arrow keys move
            // inside them.
            canRequestFocus: false,
            onTap: onTap,
            onLongPress: onLongPress,
            child: SizedBox(
              height: 34,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 10.0;
                    final showDate =
                        date != null &&
                        constraints.maxWidth >=
                            iconSize +
                                _minNameWidth +
                                _dateWidth +
                                _sizeWidth +
                                3 * spacing;
                    return Row(
                      spacing: spacing,
                      children: [
                        _icon(context, selected && showCheckmark),
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14, color: textColor),
                          ),
                        ),
                        if (showDate)
                          SizedBox(
                            width: _dateWidth,
                            child: Text(
                              DateFormat.yMMMd(locale).add_Hm().format(date!),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: secondaryStyle,
                            ),
                          ),
                        SizedBox(
                          width: _sizeWidth,
                          child: Text(
                            size,
                            maxLines: 1,
                            textAlign: TextAlign.end,
                            style: secondaryStyle,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _icon(BuildContext context, bool checked) {
    return Container(
      width: iconSize,
      height: iconSize,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(3)),
      child: checked
          ? ColoredBox(
              color: context.color.onPrimary,
              child: Icon(Icons.check, color: context.color.primary, size: 18),
            )
          : thumbnail,
    );
  }
}
