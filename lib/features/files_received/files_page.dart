import 'dart:io';

import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/features/send/qr_page.dart';
import 'package:blast_qr/features/settings/settings_page.dart';
import 'package:blast_qr/file_badge_count.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/file_extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blast_qr/widgets/blast_chip.dart';
import 'package:blast_qr/widgets/bottom_sheets.dart';
import 'package:blast_qr/widgets/logo_widget.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

enum _FilterType { all, image, video, audio, document, other }

class _DateHeader {
  final DateTime date;
  final bool isOlder;
  _DateHeader(this.date, {this.isOlder = false});
}

class FilesPage extends StatefulWidget {
  const FilesPage({super.key, this.onPickFile});

  final void Function(File? file)? onPickFile;

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  double cacheWidth = 100;
  List<FileWrapper> _files = [];
  bool _isLoading = true;
  _FilterType _selectedFilter = _FilterType.all;
  final Set<FileWrapper> _selectedFiles = {};

  bool get _isSelecting => _selectedFiles.isNotEmpty;

  void _exitSelectionMode() => setState(() => _selectedFiles.clear());

  void _onLongPressItem(FileWrapper file) {
    setState(() => _selectedFiles.add(file));
  }

  void _toggleSelection(FileWrapper file) {
    setState(() {
      if (_selectedFiles.contains(file)) {
        _selectedFiles.remove(file);
      } else {
        _selectedFiles.add(file);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadItems();

    final mediaQuery =
        (context.getElementForInheritedWidgetOfExactType<MediaQuery>()!.widget
                as MediaQuery)
            .data;
    cacheWidth =
        mediaQuery.devicePixelRatio * ((mediaQuery.size.width / 2) - 64);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FileBadgeCount>(context, listen: false).clear();
    });
  }

  Future<void> _loadItems() async {
    final directory = await getApplicationDocumentsDirectory();
    final itemsDirectory = Directory('${directory.path}/docs');

    if (await itemsDirectory.exists()) {
      final List<FileSystemEntity> files = itemsDirectory.listSync();
      _files = await Future.wait(
          files.whereType<File>().map((f) async => await f.toFileWrapper()),
        )
        ..sort((l, r) => r.modified.compareTo(l.modified));
    } else {
      _files = []; // No images found
    }
    _isLoading = false;
    setState(() {});
  }

  Set<_FilterType> get _availableFilters {
    final types = <_FilterType>{_FilterType.all};
    for (final f in _files) {
      if (f.type.isImage) {
        types.add(_FilterType.image);
      } else if (f.type.isVideo) {
        types.add(_FilterType.video);
      } else if (f.type.isAudio) {
        types.add(_FilterType.audio);
      } else if (f.type.isDocument) {
        types.add(_FilterType.document);
      } else {
        types.add(_FilterType.other);
      }
    }
    return types;
  }

  List<FileWrapper> get _filteredFiles {
    if (_selectedFilter == _FilterType.all) return _files;
    return _files.where((f) {
      switch (_selectedFilter) {
        case _FilterType.all:
          return true;
        case _FilterType.image:
          return f.type.isImage;
        case _FilterType.video:
          return f.type.isVideo;
        case _FilterType.audio:
          return f.type.isAudio;
        case _FilterType.document:
          return f.type.isDocument;
        case _FilterType.other:
          return !f.type.isImage &&
              !f.type.isVideo &&
              !f.type.isAudio &&
              !f.type.isDocument;
      }
    }).toList();
  }

  List<Object> _buildListItems() {
    final twoYearsAgo = DateUtils.dateOnly(
      DateTime.now().subtract(const Duration(days: 365 * 2)),
    );
    final grouped = <DateTime, List<FileWrapper>>{};
    final olderFiles = <FileWrapper>[];
    for (final f in _filteredFiles) {
      final day = DateUtils.dateOnly(f.modified);
      if (!day.isAfter(twoYearsAgo)) {
        olderFiles.add(f);
      } else {
        grouped.putIfAbsent(day, () => []).add(f);
      }
    }
    final sortedDays = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final items = <Object>[];
    for (final day in sortedDays) {
      items.add(_DateHeader(day));
      items.addAll(grouped[day]!);
    }
    if (olderFiles.isNotEmpty) {
      items.add(_DateHeader(DateTime(0), isOlder: true));
      items.addAll(olderFiles);
    }
    return items;
  }

  String _formatDateHeader(_DateHeader header) {
    if (header.isOlder) return context.l10n.older;
    final date = header.date;
    final now = DateUtils.dateOnly(DateTime.now());
    final yesterday = DateUtils.dateOnly(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    if (date == now) return context.l10n.today;
    if (date == yesterday) return context.l10n.yesterday;
    return DateFormat.yMMMMd(
      Localizations.localeOf(context).languageCode,
    ).format(date);
  }

  String _filterLabel(_FilterType filter) {
    switch (filter) {
      case _FilterType.all:
        return context.l10n.filter_all;
      case _FilterType.image:
        return context.l10n.filter_images;
      case _FilterType.video:
        return context.l10n.filter_videos;
      case _FilterType.audio:
        return context.l10n.filter_audio;
      case _FilterType.document:
        return context.l10n.filter_document;
      case _FilterType.other:
        return context.l10n.filter_other;
    }
  }

  Widget _buildChipsRow() {
    const orderedFilters = [
      _FilterType.all,
      _FilterType.image,
      _FilterType.video,
      _FilterType.audio,
      _FilterType.document,
      _FilterType.other,
    ];
    final available = _availableFilters;
    final chips = orderedFilters.where(available.contains).toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        spacing: 8,
        children:
            chips.map((filter) {
              return BlastChip(
                label: Text(_filterLabel(filter)),
                selected: _selectedFilter == filter,
                onSelected: (_) => setState(() => _selectedFilter = filter),
              );
            }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title:
            _isSelecting
                ? Text('${_selectedFiles.length} ${context.l10n.selected}')
                : const LogoWidget(),
        centerTitle: !_isSelecting,
        leading:
            _isSelecting
                ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _exitSelectionMode,
                )
                : null,
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        actions: [
          if (_isSelecting)
            IconButton(
              icon: const Icon(Icons.more_horiz),
              onPressed: _showMultiSelectSheet,
            )
          else
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return const SettingsPage();
                    },
                  ),
                );
              },
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedSettings01,
                color: context.color.onSurface,
              ),
            ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.9, 1.0],
              colors: [
                context.color.surface,
                context.color.surface.withAlpha(0),
              ],
            ),
          ),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          if (_files.isEmpty) {
            return Center(
              child: Column(
                spacing: 16,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedFileSearch,
                    color: context.color.onSurface,
                    size: 36,
                  ),
                  Text(context.l10n.no_files_msg),
                ],
              ),
            );
          }
          final listItems = _buildListItems();
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.top - 12,
                ),
              ),
              SliverToBoxAdapter(child: _buildChipsRow()),
              if (listItems.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text(context.l10n.no_files_msg)),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = listItems[index];
                    if (item is _DateHeader) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Text(
                          _formatDateHeader(item),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.color.onSurfaceVariant,
                          ),
                        ),
                      );
                    }
                    final file = item as FileWrapper;
                    final isSelected = _selectedFiles.contains(file);
                    return ListTile(
                      selected: _isSelecting && isSelected,
                      onTap: () {
                        if (_isSelecting) {
                          _toggleSelection(file);
                        } else {
                          _onTapItem(file);
                        }
                      },
                      onLongPress: () => _onLongPressItem(file),
                      leading: Stack(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(60),
                                  spreadRadius: 0,
                                  blurRadius: 2,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: file.buildThumbnail(context, size: 56),
                          ),
                          if (_isSelecting)
                            Positioned.fill(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? context.color.primary.withAlpha(180)
                                          : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child:
                                    isSelected
                                        ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 28,
                                        )
                                        : null,
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(file.sizeInkB),
                    );
                  }, childCount: listItems.length),
                ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 80,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onTapItem(FileWrapper file) {
    final date = file.modified;
    final dateString = DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
    showSheet(
      context: context,
      title: context.l10n.file_options,
      body: Column(
        children: [
          GestureDetector(
            onTap: () {
              _onTapOpen(file);
            },
            child: Container(
              width: 92,
              height: 92,
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
              child: file.buildThumbnail(context, size: 92),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Text(file.name, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 4),
          Text(
            dateString,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.color.secondary),
          ),
          const SizedBox(height: 8),
          ListTile(
            dense: true,
            onTap: () {
              _onTapOpen(file);
            },
            leading: HugeIcon(
              icon: HugeIcons.strokeRoundedPackageOpen,
              color: context.color.primary,
            ),
            title: Text(context.l10n.open),
          ),
          if (Platform.isAndroid)
            ListTile(
              dense: true,
              onTap: () {
                _trySaveToDownloads(file.file);
              },
              leading: HugeIcon(
                icon: HugeIcons.strokeRoundedDownload01,
                color: context.color.primary,
              ),
              title: Text(context.l10n.save_to_downloads),
            ),
          ListTile(
            dense: true,
            onTap: () {
              _onTapRename(file);
            },
            leading: HugeIcon(
              icon: HugeIcons.strokeRoundedEdit01,
              color: context.color.primary,
            ),
            title: Text(context.l10n.rename),
          ),
          ListTile(
            dense: true,
            onTap: () {
              Navigator.of(context).pop();
              _onTapSend(file);
            },
            title: Text(context.l10n.send),

            leading: HugeIcon(
              icon: HugeIcons.strokeRoundedQrCode,
              color: context.color.primary,
            ),
          ),
          ListTile(
            dense: true,
            onTap: () {
              _onTapDelete(file);
            },
            title: Text(context.l10n.delete),

            leading: HugeIcon(
              icon: HugeIcons.strokeRoundedDelete01,
              color: context.color.primary,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _onTapOpen(FileWrapper file) async {
    try {
      OpenFile.open(file.file.path, type: file.type.mimeType ?? '');
    } catch (error) {
      Navigator.of(context).pop();
      final snackBar = SnackBar(content: Text(error.toString()));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void _onTapSend(FileWrapper file) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) {
          return QrPage(file: file);
        },
      ),
    );
  }

  void _showMultiSelectSheet() {
    final files = _selectedFiles.toList();
    showSheet(
      context: context,
      title: context.l10n.selected_options,
      body: Column(
        children: [
          ListTile(
            dense: true,
            onTap: () {
              Navigator.of(context).pop();
              _sendSelectedFiles(files);
            },
            leading: HugeIcon(
              icon: HugeIcons.strokeRoundedQrCode,
              color: context.color.primary,
            ),
            title: Text(context.l10n.send),
          ),
          if (Platform.isAndroid)
            ListTile(
              dense: true,
              onTap: () {
                Navigator.of(context).pop();
                _saveAllToDownloads(files);
              },
              leading: HugeIcon(
                icon: HugeIcons.strokeRoundedDownload01,
                color: context.color.primary,
              ),
              title: Text(context.l10n.save_to_downloads),
            ),
          ListTile(
            dense: true,
            onTap: () {
              Navigator.of(context).pop();
              _deleteAllSelected(files);
            },
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

  void _sendSelectedFiles(List<FileWrapper> files) {
    _exitSelectionMode();
    Navigator.of(context).push(_qrRouteForIndex(files, 0));
  }

  Route<void> _qrRouteForIndex(List<FileWrapper> files, int index) {
    final isLast = index == files.length - 1;
    return MaterialPageRoute(
      fullscreenDialog: true,
      builder:
          (context) => QrPage(
            file: files[index],
            onNext:
                isLast
                    ? null
                    : () => Navigator.of(
                      context,
                    ).pushReplacement(_qrRouteForIndex(files, index + 1)),
          ),
    );
  }

  Future<void> _saveAllToDownloads(List<FileWrapper> files) async {
    int saved = 0;
    for (final f in files) {
      try {
        await _saveFileToDownloads(f.file);
        saved++;
      } catch (_) {}
    }
    if (mounted) {
      _exitSelectionMode();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${context.l10n.saved_to} /storage/emulated/0/Download ($saved/${files.length})',
          ),
        ),
      );
    }
  }

  Future<void> _saveFileToDownloads(File file, {String? newName}) async {
    final directory = Directory('/storage/emulated/0/Download');
    final newPath =
        '${directory.path}/${newName ?? file.uri.pathSegments.last}';
    try {
      await file.copy(newPath);
      MediaScanner.loadMedia(path: newPath);
    } catch (error) {
      if (error is PathExistsException) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final nameComps = file.uri.pathSegments.last.split('.');
        final name = nameComps.elementAtOrNull(0);
        final ext = nameComps.elementAtOrNull(1);
        await _saveFileToDownloads(
          file,
          newName: '${name ?? 'file'}_$timestamp.${ext ?? 'bin'}',
        );
      } else {
        rethrow;
      }
    }
  }

  void _deleteAllSelected(List<FileWrapper> files) {
    showMessage(
      context: context,
      title: context.l10n.delete,
      message: context.l10n.delete_files_msg,
      confirmTitle: context.l10n.yes_delete,
      secondaryTitle: context.l10n.cancel,
      onConfirmTap: () async {
        for (final f in files) {
          try {
            await f.file.delete();
          } catch (_) {}
        }
        await _loadItems();
        if (mounted) _exitSelectionMode();
      },
    );
  }

  void _onTapRename(FileWrapper file) {
    Navigator.of(context).pop();
    // To select only filename without extension
    final dotIndex = file.name.indexOf('.');
    final selection = TextSelection(baseOffset: 0, extentOffset: dotIndex);
    showTextInputSheet(
      context,
      title: context.l10n.rename,
      hintText: context.l10n.file_name,
      prefilledText: file.name,
      selection: selection,
      confirmText: context.l10n.save,
      onConfirm: (newName) {
        _tryRenameFile(file.file, newName);
      },
    );
  }

  Future<void> _tryRenameFile(File file, String newName) async {
    try {
      final path = file.path;
      final lastSeparator = path.lastIndexOf(Platform.pathSeparator);
      final newPath = path.substring(0, lastSeparator + 1) + newName;
      if (await File(newPath).exists()) {
        throw Exception('File with that name already exists.');
      }
      await file.rename(newPath);
      await _loadItems();
    } catch (error) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(error.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  Future<void> _onTapDelete(FileWrapper file) async {
    Navigator.of(context).pop();
    showMessage(
      context: context,
      title: context.l10n.delete,
      message: context.l10n.delete_msg,
      confirmTitle: context.l10n.yes_delete,
      secondaryTitle: context.l10n.cancel,
      onConfirmTap: () {
        _tryDeleteFile(file.file);
      },
    );
  }

  Future<void> _tryDeleteFile(File file) async {
    try {
      await file.delete();
      await _loadItems();
    } catch (error) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(error.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  void _trySaveToDownloads(File file, {String? newName}) async {
    try {
      await _saveFileToDownloads(file, newName: newName);
      if (mounted) {
        Navigator.of(context).pop();
        final newPath =
            '/storage/emulated/0/Download/${newName ?? file.uri.pathSegments.last}';
        final snackBar = SnackBar(
          content: Text('${context.l10n.saved_to} $newPath'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (error) {
      if (mounted) {
        Navigator.of(context).pop();
        final snackBar = SnackBar(content: Text(error.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }
}
