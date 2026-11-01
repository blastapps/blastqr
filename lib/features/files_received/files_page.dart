import 'dart:io';

import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/features/files_received/save_to_downloads.dart';
import 'package:blast_qr/features/files_received/received_items.dart';
import 'package:blast_qr/features/files_received/widgets/file_options_sheet.dart';
import 'package:blast_qr/features/files_received/widgets/qr_code_sheet.dart';
import 'package:blast_qr/features/files_received/widgets/received_item_tile.dart';
import 'package:blast_qr/features/send/send_files.dart';
import 'package:blast_qr/features/send/send_options.dart';
import 'package:blast_qr/features/send/widgets/custom_password_sheet.dart';
import 'package:blast_qr/features/settings/settings_page.dart';
import 'package:blast_qr/file_badge_count.dart';
import 'package:blast_qr/file_name_utils.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/file_extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blast_qr/model/scanned_qr_code.dart';
import 'package:blast_qr/received_files_directory.dart';
import 'package:blast_qr/widgets/blast_chip.dart';
import 'package:blast_qr/widgets/bottom_sheets.dart';
import 'package:blast_qr/widgets/circle_button.dart';
import 'package:blast_qr/widgets/logo_widget.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';

class FilesPage extends StatefulWidget {
  const FilesPage({super.key});

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  static const _chipsOverlap = 12.0;

  /// Newest first. Created once per load so selection can match by identity.
  List<ReceivedItem> _items = [];
  bool _isLoading = true;
  ReceivedFilter _selectedFilter = ReceivedFilter.all;
  final Set<ReceivedItem> _selectedItems = {};
  late final AppSettings _appSettings;
  late bool _showInFilesApp;

  bool get _isSelecting => _selectedItems.isNotEmpty;

  void _exitSelectionMode() => setState(() => _selectedItems.clear());

  void _toggleSelection(ReceivedItem item) {
    setState(() {
      if (!_selectedItems.remove(item)) _selectedItems.add(item);
    });
  }

  @override
  void initState() {
    super.initState();
    _appSettings = Provider.of<AppSettings>(context, listen: false)
      ..addListener(_onSettingsChanged);
    _showInFilesApp = _appSettings.showInFilesApp;
    _loadItems();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FileBadgeCount>(context, listen: false).clear();
    });
  }

  @override
  void dispose() {
    _appSettings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  // Changing the setting moves the files to another directory.
  void _onSettingsChanged() {
    if (_appSettings.showInFilesApp == _showInFilesApp) return;
    _showInFilesApp = _appSettings.showInFilesApp;
    _selectedItems.clear();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final itemsDirectory = await receivedFilesDirectory();
    final files = await Future.wait(
      itemsDirectory.listSync().whereType<File>().map((f) => f.toFileWrapper()),
    );
    final qrCodes = await loadScannedQrCodes(await qrCodesDirectory());
    _items = [
      ...files.map(ReceivedFile.new),
      ...qrCodes.map(ReceivedQrCode.new),
    ]..sort((l, r) => r.date.compareTo(l.date));
    _isLoading = false;
    if (!mounted) return;
    setState(() {});
  }

  List<ReceivedItem> get _filteredItems => _selectedFilter == ReceivedFilter.all
      ? _items
      : _items.where((item) => item.filter == _selectedFilter).toList();

  String _formatDateHeader(DateHeader header) {
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

  String _filterLabel(ReceivedFilter filter) => switch (filter) {
    ReceivedFilter.all => context.l10n.filter_all,
    ReceivedFilter.image => context.l10n.filter_images,
    ReceivedFilter.video => context.l10n.filter_videos,
    ReceivedFilter.audio => context.l10n.filter_audio,
    ReceivedFilter.document => context.l10n.filter_document,
    ReceivedFilter.book => context.l10n.filter_book,
    ReceivedFilter.other => context.l10n.filter_other,
    ReceivedFilter.qr => context.l10n.filter_qr,
  };

  Widget _buildChipsRow() {
    final available = {
      ReceivedFilter.all,
      for (final item in _items) item.filter,
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        spacing: 8,
        children: [
          for (final filter in ReceivedFilter.values)
            if (available.contains(filter))
              BlastChip(
                label: Text(_filterLabel(filter)),
                selected: _selectedFilter == filter,
                onSelected: (_) => setState(() => _selectedFilter = filter),
              ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: _isSelecting
            ? Text('${_selectedItems.length} ${context.l10n.selected}')
            : const LogoWidget(),
        centerTitle: !_isSelecting,
        leading: _isSelecting
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
            CircleButton(
              icon: const Icon(Icons.more_horiz),
              onPressed: _showMultiSelectSheet,
            )
          else
            CircleButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return const SettingsPage();
                    },
                  ),
                );
              },
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedSettings01),
            ),
        ],
        // The chips row tucks 12px under the bar, so fade over those 12px.
        flexibleSpace: LayoutBuilder(
          builder: (context, constraints) {
            final fadeStart = 1 - _chipsOverlap / constraints.maxHeight;
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [fadeStart, 1.0],
                  colors: [
                    context.color.surface,
                    context.color.surface.withAlpha(0),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      body: Builder(
        builder: (context) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          if (_items.isEmpty) {
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
          final rows = groupByDay(_filteredItems);
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.top - _chipsOverlap,
                ),
              ),
              SliverToBoxAdapter(child: _buildChipsRow()),
              if (rows.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text(context.l10n.no_files_msg)),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => switch (rows[index]) {
                      final DateHeader header => Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Text(
                          _formatDateHeader(header),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.color.onSurfaceVariant,
                          ),
                        ),
                      ),
                      final ReceivedItem item => ReceivedItemTile(
                        item: item,
                        isSelecting: _isSelecting,
                        isSelected: _selectedItems.contains(item),
                        onTap: () => _onTapItem(item),
                        onLongPress: () =>
                            setState(() => _selectedItems.add(item)),
                      ),
                    },
                    childCount: rows.length,
                  ),
                ),
              SliverToBoxAdapter(
                child: SizedBox(height: MediaQuery.of(context).padding.bottom),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onTapItem(ReceivedItem item) {
    if (_isSelecting) {
      _toggleSelection(item);
      return;
    }
    switch (item) {
      case ReceivedFile(:final file):
        showFileOptionsSheet(
          context,
          file,
          onOpen: () => _onTapOpen(file),
          onSaveToDownloads: () => _trySaveToDownloads(file.file),
          onRename: () => _onTapRename(file),
          onSend: (options) => sendFiles(context, [file], options),
          onDelete: () => _onTapDelete(file.file),
        );
      case ReceivedQrCode(:final code):
        showQrCodeSheet(context, code, onDelete: () => _onTapDelete(code.file));
    }
  }

  void _onTapOpen(FileWrapper file) async {
    try {
      OpenFile.open(file.file.path, type: file.type.mimeType ?? '');
    } catch (error) {
      Navigator.of(context).pop();
      _showError(error);
    }
  }

  Future<void> _showMultiSelectSheet() async {
    final files = await Future.wait(
      _selectedItems.map((item) => item.toFileWrapper()),
    );
    if (!mounted) return;
    showSheet(
      context: context,
      title: context.l10n.selected_options,
      body: Column(
        children: [
          SendTile(
            onTap: () {
              Navigator.of(context).pop();
              _sendSelectedFiles(files, plainSend);
            },
          ),
          SendEncryptedTile(
            onTap: () {
              Navigator.of(context).pop();
              _sendSelectedFiles(files, encryptedSend());
            },
            onLongPress: () async {
              Navigator.of(context).pop();
              final password = await showCustomPasswordSheet(context);
              if (password == null || !mounted) return;
              _sendSelectedFiles(files, (password: password, fileName: null));
            },
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
              _deleteAllSelected([for (final f in files) f.file]);
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

  void _sendSelectedFiles(List<FileWrapper> files, SendOptions options) {
    _exitSelectionMode();
    sendFiles(context, files, options);
  }

  Future<void> _saveAllToDownloads(List<FileWrapper> files) async {
    int saved = 0;
    for (final f in files) {
      try {
        await saveToDownloads(f.file);
        saved++;
      } catch (_) {}
    }
    if (mounted) {
      _exitSelectionMode();
      _showSnackBar(
        '${context.l10n.saved_to} $androidDownloadsPath ($saved/${files.length})',
      );
    }
  }

  void _trySaveToDownloads(File file) async {
    try {
      final path = await saveToDownloads(file);
      if (mounted) {
        Navigator.of(context).pop();
        _showSnackBar('${context.l10n.saved_to} $path');
      }
    } catch (error) {
      if (mounted) {
        Navigator.of(context).pop();
        _showError(error);
      }
    }
  }

  void _deleteAllSelected(List<File> files) {
    showMessage(
      context: context,
      title: context.l10n.delete,
      message: context.l10n.delete_files_msg,
      confirmTitle: context.l10n.yes_delete,
      secondaryTitle: context.l10n.cancel,
      onConfirmTap: () async {
        for (final f in files) {
          try {
            await f.delete();
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
    final selection = TextSelection(
      baseOffset: 0,
      extentOffset: dotIndex > 0 ? dotIndex : file.name.length,
    );
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
      final newPath =
          path.substring(0, lastSeparator + 1) + sanitizeFileName(newName);
      if (await File(newPath).exists()) {
        throw Exception('File with that name already exists.');
      }
      await file.rename(newPath);
      await _loadItems();
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _onTapDelete(File file) async {
    Navigator.of(context).pop();
    showMessage(
      context: context,
      title: context.l10n.delete,
      message: context.l10n.delete_msg,
      confirmTitle: context.l10n.yes_delete,
      secondaryTitle: context.l10n.cancel,
      onConfirmTap: () {
        _tryDeleteFile(file);
      },
    );
  }

  Future<void> _tryDeleteFile(File file) async {
    try {
      await file.delete();
      await _loadItems();
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  void _showError(Object error) => _showSnackBar(error.toString());

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
