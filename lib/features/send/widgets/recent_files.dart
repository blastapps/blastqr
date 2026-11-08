import 'dart:io';

import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blast_qr/widgets/file_list_row.dart';
import 'package:blast_qr/widgets/file_list_selection.dart';
import 'package:blast_qr/widgets/file_list_tile.dart';
import 'package:blast_qr/widgets/selection_bar.dart';
import 'package:flutter/material.dart';

/// Phone recents: tap sends a file, long-press starts selecting several,
/// which are sent from the selection bar.
class RecentFilesTiles extends StatefulWidget {
  const RecentFilesTiles({
    super.key,
    required this.entries,
    required this.bottomInset,
    required this.onSend,
    required this.onClear,
  });

  final List<FileWrapper> entries;

  /// The height of the bottom tabs, which the list runs under.
  final double bottomInset;
  final void Function(List<File>) onSend;
  final VoidCallback onClear;

  @override
  State<RecentFilesTiles> createState() => _RecentFilesTilesState();
}

class _RecentFilesTilesState extends State<RecentFilesTiles>
    with SelectionBarOwner<RecentFilesTiles> {
  late final _selection = FileListSelection<FileWrapper>(() => widget.entries)
    ..addListener(_onSelectionChanged);

  bool get _selecting => _selection.isNotEmpty;

  void _onSelectionChanged() {
    setState(() {});
    updateSelectionBar(_selection, onOpen: () => _send(_selection.selected));
  }

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  void _send(List<FileWrapper> entries) {
    // Sending moves the files to the top of the list.
    _selection.clear();
    if (entries.isNotEmpty) {
      widget.onSend([for (final entry in entries) entry.file]);
    }
  }

  void _clear() {
    _selection.clear();
    widget.onClear();
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RecentHeader(horizontalPadding: 16, onClear: _clear),
        Expanded(
          child: ListView.builder(
            // Room to scroll the last file above the tabs.
            padding: EdgeInsets.only(bottom: widget.bottomInset),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return FileListTile(
                thumbnail: entry.buildThumbnail(
                  context,
                  size: FileListTile.thumbnailSize,
                ),
                title: entry.name,
                subtitle: entry.sizeInkB,
                isSelecting: _selecting,
                isSelected: _selection.contains(entry),
                onTap: _selecting
                    ? () => _selection.toggle(entry)
                    : () => _send([entry]),
                onLongPress: () => _selection.toggle(entry),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Desktop recents: a file list that works like the Received page, where
/// opening the selection sends it.
class RecentFilesList extends StatefulWidget {
  const RecentFilesList({
    super.key,
    required this.entries,
    required this.onSend,
    required this.onClear,
  });

  final List<FileWrapper> entries;
  final void Function(List<File>) onSend;
  final VoidCallback onClear;

  @override
  State<RecentFilesList> createState() => _RecentFilesListState();
}

class _RecentFilesListState extends State<RecentFilesList>
    with SelectionBarOwner<RecentFilesList> {
  late final _selection = FileListSelection<FileWrapper>(() => widget.entries)
    ..addListener(_onSelectionChanged);

  void _onSelectionChanged() {
    setState(() {});
    updateSelectionBar(_selection, onOpen: () => _send(_selection.selected));
  }

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  void _send(List<FileWrapper> entries) {
    // Sending moves the files to the top of the list.
    _selection.clear();
    widget.onSend([for (final entry in entries) entry.file]);
  }

  void _clear() {
    _selection.clear();
    widget.onClear();
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        _RecentHeader(horizontalPadding: 8, onClear: _clear),
        Expanded(
          child: FileListKeyboard(
            selection: _selection,
            onOpen: _send,
            child: ListView.builder(
              // Room to scroll the last file above the selection bar.
              padding: EdgeInsets.only(
                bottom: showsSelectionBar ? SelectionBar.height : 0,
              ),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return FileListRow(
                  key: entry == _selection.cursor ? _selection.cursorKey : null,
                  thumbnail: entry.buildThumbnail(
                    context,
                    size: FileListRow.iconSize,
                  ),
                  name: entry.name,
                  size: entry.sizeInkB,
                  striped: index.isOdd,
                  selected: _selection.contains(entry),
                  showCheckmark: _selection.length > 1,
                  margin: EdgeInsets.zero,
                  onTap: () => _selection.tap(entry, _send),
                  onLongPress: () => _selection.longPress(entry),
                  onSecondaryTap: () => _selection.secondaryTap(entry, _send),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentHeader extends StatelessWidget {
  const _RecentHeader({required this.horizontalPadding, required this.onClear});

  final double horizontalPadding;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: horizontalPadding,
        end: horizontalPadding - 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.recent,
              style: const TextStyle(fontFamily: 'Jersey25', fontSize: 18),
            ),
          ),
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
            ),
            child: Text(context.l10n.clear_recent),
          ),
        ],
      ),
    );
  }
}
