import 'dart:async';
import 'dart:io';

import 'package:blast_qr/acoustic_ack_listener.dart';
import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/features/send/send_files.dart';
import 'package:blast_qr/features/send/send_options.dart';
import 'package:blast_qr/features/settings/settings_page.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/blast_qrcode_data.dart';
import 'package:blast_qr/model/file_extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blast_qr/platform_support.dart';
import 'package:blast_qr/widgets/bottom_sheets.dart';
import 'package:blast_qr/widgets/circle_button.dart';
import 'package:blast_qr/widgets/logo_widget.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:path_provider/path_provider.dart';

class SendPage extends StatefulWidget {
  const SendPage({super.key});

  @override
  State<SendPage> createState() => _SendPageState();
}

class _SendPageState extends State<SendPage> {
  final List<FileWrapper> _recentFiles = [];

  void _addRecentFile(FileWrapper fw) {
    setState(() {
      _recentFiles.removeWhere((e) => e.file.path == fw.file.path);
      _recentFiles.insert(0, fw);
      if (_recentFiles.length > 15) _recentFiles.removeLast();
    });
  }

  Widget _dropRegion({required Widget child}) {
    return DropTarget(
      onDragDone: (details) async {
        final files = await _copyDroppedFiles(details.files);
        if (files.isNotEmpty && mounted) _showQrPages(files);
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const LogoWidget(),
        centerTitle: true,
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
      ),
      body: _dropRegion(
        child: Column(
          children: [
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: Column(
                spacing: 8,
                children: [
                  _SendCard(
                    icon: HugeIcons.strokeRoundedFileAdd,
                    title: context.l10n.send_file,
                    subtitle: context.l10n.send_file_subtitle,
                    onTap: _pickFileToEncode,
                  ),
                  _SendCard(
                    icon: HugeIcons.strokeRoundedImageAdd01,
                    title: context.l10n.send_picture,
                    subtitle: context.l10n.send_picture_subtitle,
                    flipIcon: true,
                    onTap: _pickImageToEncode,
                  ),
                ],
              ),
            ),
            // Recents sit in the lower half so the send buttons stay
            // centered whether or not they are shown.
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  spacing: 16,
                  children: [
                    _RecentFilesRow(
                      entries: _recentFiles,
                      onFileTap: _showQrPage,
                      onSendSelected: _showQrPages,
                    ),
                    if (!canScanWithCamera)
                      Text(context.l10n.desktop_receive_unsupported),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pickFileToEncode() async {
    const XTypeGroup typeGroup = XTypeGroup(label: 'files');
    final List<XFile> files = await openFiles(
      acceptedTypeGroups: <XTypeGroup>[typeGroup],
    );
    if (files.isNotEmpty && mounted) {
      _showQrPages(files.map((f) => File(f.path)).toList());
    }
  }

  void _pickImageToEncode() async {
    final picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty && mounted) {
      _showQrPages(images.map((f) => File(f.path)).toList());
    }
  }

  /// Dropped files are only readable during the drop (macOS sandbox access is
  /// scoped to it), so copy them somewhere the app can keep using.
  Future<List<File>> _copyDroppedFiles(List<DropItem> items) async {
    final dir = await (await getTemporaryDirectory()).createTemp('dropped_');
    final files = <File>[];
    for (final item in items.whereType<DropItemFile>()) {
      final bookmark = item.extraAppleBookmark;
      final accessing =
          bookmark != null &&
          await DesktopDrop.instance.startAccessingSecurityScopedResource(
            bookmark: bookmark,
          );
      try {
        files.add(await File(item.path).copy('${dir.path}/${item.name}'));
      } on FileSystemException {
        // Skip files we can't read.
      } finally {
        if (accessing) {
          await DesktopDrop.instance.stopAccessingSecurityScopedResource(
            bookmark: bookmark,
          );
        }
      }
    }
    return files;
  }

  void _showQrPage(File file) {
    _showQrPages([file]);
  }

  void _showQrPages(List<File> files) async {
    final fileWrappers = await Future.wait(files.map((f) => f.toFileWrapper()));
    if (!mounted) return;

    final mtu = Provider.of<EncodeSettings>(context, listen: false).mtu;
    final symbolSize = BlastQrcodeData.symbolSizeForMtu(mtu);
    for (final fileWrapper in fileWrappers) {
      if (fileWrapper.size > BlastQrcodeData.maxFileBytes) {
        showFileTooLarge(context, context.l10n.file_too_large_msg);
        return;
      }
      // Receivers reject transfers with too many symbols, which only happens
      // with big files at a small QR code size.
      final transferLength =
          fileWrapper.size + BlastQrcodeData.maxMetadataBytes;
      if (!BlastQrcodeData.fitsSymbolLimit(transferLength, symbolSize)) {
        showFileTooLarge(context, context.l10n.file_too_large_for_qr_size_msg);
        return;
      }
    }

    final options = await chooseSendOptions(context, fileWrappers);
    if (options == null || !mounted) return;

    await sendFiles(context, fileWrappers, options);
    if (mounted) {
      for (final fw in fileWrappers) {
        _addRecentFile(fw);
      }
    }
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) await _maybeShowMicPrompt();
    }
  }

  Future<void> _maybeShowMicPrompt() async {
    final appSettings = Provider.of<AppSettings>(context, listen: false);
    if (appSettings.acousticDetection || appSettings.hasSeenMicPrompt) return;
    appSettings.updateHasSeenMicPrompt(true);
    await showMessage(
      context: context,
      title: context.l10n.mic_permission_title,
      message: context.l10n.mic_permission_message,
      confirmTitle: context.l10n.mic_permission_allow,
      secondaryTitle: context.l10n.cancel,
      onConfirmTap: () async {
        final granted = await AcousticAckListener.requestPermission();
        if (mounted && granted) {
          appSettings.updateAcousticDetection(true);
        }
      },
    );
  }
}

Color _cardFill(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? context.color.primaryContainer
    : context.color.surface;

class _SendCard extends StatelessWidget {
  const _SendCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.flipIcon,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool? flipIcon;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(4);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: radius,
      onTap: onTap,
      // Ink rather than Container, so the tap ripple shows over the fill.
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: context.color.outline),
          color: _cardFill(context),
          borderRadius: radius,
        ),
        child: Row(
          spacing: 14,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.color.primary.withValues(
                  alpha: isDark ? 0.25 : 0.1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Transform.flip(
                flipX: flipIcon == true,
                child: HugeIcon(
                  icon: icon,
                  color: context.color.primary,
                  size: 26,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Jersey25',
                      fontSize: 22,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.color.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              color: context.color.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentFilesRow extends StatefulWidget {
  const _RecentFilesRow({
    required this.entries,
    required this.onFileTap,
    required this.onSendSelected,
  });

  final List<FileWrapper> entries;
  final void Function(File) onFileTap;
  final void Function(List<File>) onSendSelected;

  @override
  State<_RecentFilesRow> createState() => _RecentFilesRowState();
}

class _RecentFilesRowState extends State<_RecentFilesRow> {
  final Set<String> _selectedPaths = {};

  bool get _selecting => _selectedPaths.isNotEmpty;

  void _toggle(FileWrapper entry) {
    setState(() {
      final path = entry.file.path;
      if (!_selectedPaths.remove(path)) _selectedPaths.add(path);
    });
  }

  void _clearSelection() => setState(_selectedPaths.clear);

  void _sendSelected() {
    final files = [
      for (final entry in widget.entries)
        if (_selectedPaths.contains(entry.file.path)) entry.file,
    ];
    _clearSelection();
    if (files.isNotEmpty) widget.onSendSelected(files);
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    if (entries.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
          child: SizedBox(
            height: 24,
            child: Row(
              spacing: 4,
              children: [
                Text(
                  _selecting
                      ? '${_selectedPaths.length} ${context.l10n.selected}'
                      : context.l10n.recent,
                  style: const TextStyle(fontFamily: 'Jersey25', fontSize: 18),
                ),
                if (_selecting)
                  IconButton(
                    onPressed: _clearSelection,
                    tooltip: context.l10n.cancel,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 24,
                      height: 24,
                    ),
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      color: context.color.onSurface,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            scrollDirection: Axis.horizontal,
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _RecentFileChip(
                entry: entry,
                selected: _selectedPaths.contains(entry.file.path),
                onTap: _selecting
                    ? () => _toggle(entry)
                    : () => widget.onFileTap(entry.file),
                onLongPress: () => _toggle(entry),
              );
            },
          ),
        ),
        Visibility(
          visible: _selecting,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            child: OutlinedButton(
              onPressed: _sendSelected,
              child: Text(context.l10n.send_selected),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentFileChip extends StatelessWidget {
  const _RecentFileChip({
    required this.entry,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final FileWrapper entry;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        decoration: BoxDecoration(
          color: _cardFill(context),
          border: Border.all(
            color: selected ? context.color.primary : context.color.outline,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 6,
          children: [
            Container(
              width: 32,
              height: 32,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
              child: selected
                  ? ColoredBox(
                      color: context.color.primary,
                      child: Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedTick02,
                          color: context.color.onPrimary,
                          size: 20,
                        ),
                      ),
                    )
                  : entry.buildThumbnail(context, size: 36),
            ),
            Expanded(
              child: Text(
                entry.name,
                style: Theme.of(context).textTheme.labelSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
