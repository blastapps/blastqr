import 'dart:async';
import 'dart:io';

import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/features/files_received/received_item_actions.dart';
import 'package:blast_qr/features/files_received/received_items.dart';
import 'package:blast_qr/features/settings/settings_page.dart';
import 'package:blast_qr/file_badge_count.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/file_extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blast_qr/model/scanned_qr_code.dart';
import 'package:blast_qr/platform_support.dart';
import 'package:blast_qr/received_files_directory.dart';
import 'package:blast_qr/widgets/blast_chip.dart';
import 'package:blast_qr/widgets/circle_button.dart';
import 'package:blast_qr/widgets/file_list_row.dart';
import 'package:blast_qr/widgets/file_list_selection.dart';
import 'package:blast_qr/widgets/file_list_tile.dart';
import 'package:blast_qr/widgets/logo_widget.dart';
import 'package:blast_qr/widgets/selection_bar.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class FilesPage extends StatefulWidget {
  const FilesPage({super.key});

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage>
    with ReceivedItemActions<FilesPage>, SelectionBarOwner<FilesPage> {
  static const _chipsOverlap = 12.0;

  /// Newest first. Created once per load so selection can match by identity.
  List<ReceivedItem> _items = [];
  bool _isLoading = true;
  ReceivedFilter _selectedFilter = ReceivedFilter.all;
  late final _selection = FileListSelection<ReceivedItem>(() => _filteredItems)
    ..addListener(_onSelectionChanged);
  late final AppSettings _appSettings;
  final List<StreamSubscription<FileSystemEvent>> _folderWatchers = [];
  Timer? _reloadTimer;
  AppLifecycleListener? _lifecycleListener;
  late bool _showInFilesApp;

  @override
  FileListSelection<ReceivedItem> get selection => _selection;

  @override
  Future<void> reloadItems() => _loadItems();

  bool get _isSelecting => _selection.isNotEmpty;

  void _onSelectionChanged() {
    setState(() {});
    updateSelectionBar(
      _selection,
      onOpen: () => openItems(_selection.selected),
    );
  }

  @override
  void initState() {
    super.initState();
    _appSettings = Provider.of<AppSettings>(context, listen: false)
      ..addListener(_onSettingsChanged);
    _showInFilesApp = _appSettings.showInFilesApp;
    _loadItems();
    _watchFolders();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FileBadgeCount>(context, listen: false).clear();
    });
  }

  @override
  void dispose() {
    _appSettings.removeListener(_onSettingsChanged);
    for (final watcher in _folderWatchers) {
      watcher.cancel();
    }
    _reloadTimer?.cancel();
    _lifecycleListener?.dispose();
    _selection.dispose();
    super.dispose();
  }

  // Changing the setting moves the files to another directory.
  void _onSettingsChanged() {
    if (_appSettings.showInFilesApp == _showInFilesApp) return;
    _showInFilesApp = _appSettings.showInFilesApp;
    _loadItems();
  }

  /// Reloads when other apps (a file manager, Finder, the Files app) add,
  /// delete or rename files. iOS can't watch folders, so there it reloads
  /// when the app comes back to the foreground.
  Future<void> _watchFolders() async {
    if (!FileSystemEntity.isWatchSupported) {
      _lifecycleListener = AppLifecycleListener(onResume: _scheduleReload);
      return;
    }
    final folders = [await receivedFilesDirectory(), await qrCodesDirectory()];
    for (final folder in folders) {
      if (!mounted) return;
      if (!await folder.exists()) continue;
      _folderWatchers.add(
        folder.watch().listen(
          (_) => _scheduleReload(),
          onError: (Object error) => debugPrint('Folder watch failed: $error'),
        ),
      );
    }
  }

  // Changes often come in bursts, like a copy or a save.
  void _scheduleReload() {
    _reloadTimer?.cancel();
    _reloadTimer = Timer(const Duration(milliseconds: 300), _loadItems);
  }

  Future<void> _loadItems() async {
    final itemsDirectory = await receivedFilesDirectory();
    final files = (await Future.wait(
      itemsDirectory.listSync().whereType<File>().map(_tryFileWrapper),
    )).nonNulls;
    final qrCodes = await loadScannedQrCodes(await qrCodesDirectory());
    _items = [
      ...files.map(ReceivedFile.new),
      ...qrCodes.map(ReceivedQrCode.new),
    ]..sort((l, r) => r.date.compareTo(l.date));
    _isLoading = false;
    if (!mounted) return;
    // The items are new, so the old selection no longer matches.
    _selection.clear();
    setState(() {});
  }

  /// Null for a file another app deleted or moved while loading.
  Future<FileWrapper?> _tryFileWrapper(File file) async {
    try {
      return await file.toFileWrapper();
    } on FileSystemException {
      return null;
    }
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
      // On desktop the row stops at its ends. Bouncing made it jump back and
      // forth while scrolling with a trackpad.
      physics: isDesktopOS ? const ClampingScrollPhysics() : null,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        spacing: 8,
        children: [
          for (final filter in ReceivedFilter.values)
            if (available.contains(filter))
              BlastChip(
                label: Text(_filterLabel(filter)),
                selected: _selectedFilter == filter,
                onSelected: (_) {
                  setState(() => _selectedFilter = filter);
                  _selection.clear();
                },
              ),
        ],
      ),
    );
  }

  Widget _buildCompactList(List<ReceivedItem> items) {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 12),
      sliver: SliverList.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return FileListRow(
            key: item == _selection.cursor ? _selection.cursorKey : null,
            thumbnail: item.thumbnail(context, FileListRow.iconSize),
            name: item.title(context),
            date: item.date,
            size: item.sizeLabel,
            striped: index.isOdd,
            selected: _selection.contains(item),
            showCheckmark: _selection.length > 1,
            onTap: () => _selection.tap(item, openItems),
            onLongPress: () => _selection.longPress(item),
            onSecondaryTap: () => _selection.secondaryTap(item, openItems),
          );
        },
      ),
    );
  }

  Widget _buildTiles(List<ReceivedRow> rows) {
    return SliverList(
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
          final ReceivedItem item => FileListTile(
            thumbnail: item.thumbnail(context, FileListTile.thumbnailSize),
            title: item.title(context),
            subtitle: item.sizeLabel,
            isSelecting: _isSelecting,
            isSelected: _selection.contains(item),
            onTap: () => _onTapItem(item),
            onLongPress: () => _selection.add(item),
          ),
        },
        childCount: rows.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.useDesktopLayout
          ? context.translucentSurface
          : Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: context.useDesktopLayout
          ? null
          : AppBar(
              title: const LogoWidget(),
              centerTitle: true,
              automaticallyImplyLeading: false,
              toolbarHeight: 80,
              surfaceTintColor: Colors.transparent,
              backgroundColor: Colors.transparent,
              actions: [
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
          final items = _filteredItems;
          final list = CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: context.useDesktopLayout
                      ? 12
                      : MediaQuery.of(context).padding.top - _chipsOverlap,
                ),
              ),
              SliverToBoxAdapter(child: _buildChipsRow()),
              if (items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text(context.l10n.no_files_msg)),
                )
              else if (context.useDesktopLayout)
                _buildCompactList(items)
              else
                _buildTiles(groupByDay(items)),
              SliverToBoxAdapter(
                child: SizedBox(
                  // On desktop, room for the selection bar while it shows.
                  height: context.useDesktopLayout
                      ? 16 + (showsSelectionBar ? SelectionBar.height + 16 : 0)
                      : MediaQuery.of(context).padding.bottom,
                ),
              ),
            ],
          );
          if (!context.useDesktopLayout) return list;
          return FileListKeyboard(
            selection: _selection,
            autofocus: true,
            onOpen: openItems,
            child: list,
          );
        },
      ),
    );
  }

  void _onTapItem(ReceivedItem item) {
    if (_isSelecting) {
      _selection.toggle(item);
      return;
    }
    showItemOptions(item);
  }
}
