import 'dart:io';

import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/features/help/help_page.dart';
import 'package:blast_qr/features/send/qr_page.dart';
import 'package:blast_qr/features/settings/settings_page.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/file_extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blast_qr/widgets/logo_widget.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

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
      if (_recentFiles.length > 5) _recentFiles.removeLast();
    });
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
        actions: [
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
      ),
      body: DropRegion(
        // Formats this region can accept.
        formats: Formats.standardFormats,
        hitTestBehavior: HitTestBehavior.opaque,
        onDropOver: (event) {
          return DropOperation.copy;
        },
        onPerformDrop: (event) async {
          final item = event.session.items.first;
          final reader = item.dataReader!;
          reader.getValue<Uri>(Formats.fileUri, (fileUri) {
            debugPrint('Dropped file: $fileUri');
            if (fileUri != null) {
              _showQrPage(File(fileUri.path));
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            spacing: 16,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _pickFileToEncode,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        height: 180,
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: context.color.outline,
                            width: 1,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              context.color.surface.withAlpha(0),
                              context.color.primaryContainer,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 16,
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedFileAdd,
                              color: context.color.onSurface,
                              size: 56,
                            ),
                            Text(
                              context.l10n.send_file,
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _pickImageToEncode,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        height: 180,
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: context.color.outline,
                            width: 1,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              context.color.surface.withAlpha(0),
                              context.color.primaryContainer,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 16,
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedImageAdd01,
                              color: context.color.onSurface,
                              size: 56,
                            ),
                            Text(
                              context.l10n.send_picture,
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              _RecentFilesRow(entries: _recentFiles, onFileTap: _showQrPage),
              OutlinedButton(
                onPressed: _onTapHelp,
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedHelpCircle,
                      color: context.color.onSurface,
                    ),
                    Text(context.l10n.help),
                  ],
                ),
              ),
              if (!Platform.isAndroid && !Platform.isIOS)
                Column(
                  spacing: 16,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Text(context.l10n.desktop_receive_unsupported)],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickFileToEncode() async {
    const XTypeGroup typeGroup = XTypeGroup(label: 'files');
    final XFile? file = await openFile(
      acceptedTypeGroups: <XTypeGroup>[typeGroup],
    );
    if (file != null && mounted) {
      final platformFile = File(file.path);
      _showQrPage(platformFile);
    }
  }

  void _pickImageToEncode() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      final platformFile = File(image.path);
      _showQrPage(platformFile);
    }
  }

  void _showQrPage(File file) async {
    final fileWrapper = await file.toFileWrapper();
    if (!mounted) return;

    const maxFileSize = 4 * 1024 * 1024 * 1024; // 4 GB
    if (fileWrapper.size > maxFileSize) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(context.l10n.file_too_large),
              content: Text(context.l10n.file_too_large_msg),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(context.l10n.ok),
                ),
              ],
            ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) {
          return QrPage(file: fileWrapper);
        },
      ),
    );
    if (mounted) _addRecentFile(fileWrapper);
  }

  void _onTapHelp() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) {
          return const HelpPage();
        },
      ),
    );
  }
}

class _RecentFilesRow extends StatelessWidget {
  const _RecentFilesRow({required this.entries, required this.onFileTap});

  final List<FileWrapper> entries;
  final void Function(File) onFileTap;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(
          context.l10n.recent,
          style: const TextStyle(fontFamily: 'Jersey25', fontSize: 18),
        ),
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _RecentFileChip(
                entry: entry,
                onTap: () => onFileTap(entry.file),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RecentFileChip extends StatelessWidget {
  const _RecentFileChip({required this.entry, required this.onTap});

  final FileWrapper entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        decoration: BoxDecoration(
          border: Border.all(color: context.color.outline, width: 1),
          borderRadius: BorderRadius.circular(12),
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
              child: entry.buildThumbnail(context, size: 36),
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
