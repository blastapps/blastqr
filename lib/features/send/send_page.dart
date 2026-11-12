import 'dart:async';
import 'dart:io';

import 'package:blast_qr/acoustic_ack_listener.dart';
import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/features/send/send_files.dart';
import 'package:blast_qr/features/send/send_options.dart';
import 'package:blast_qr/features/send/widgets/drop_zone.dart';
import 'package:blast_qr/features/send/widgets/recent_files.dart';
import 'package:blast_qr/features/settings/settings_page.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/file_extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blast_qr/pick_files.dart';
import 'package:blast_qr/platform_support.dart';
import 'package:blast_qr/temp_files.dart';
import 'package:blast_qr/widgets/bottom_sheets.dart';
import 'package:blast_qr/widgets/circle_button.dart';
import 'package:blast_qr/widgets/logo_widget.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

class SendPage extends StatefulWidget {
  const SendPage({super.key});

  @override
  State<SendPage> createState() => SendPageState();
}

class SendPageState extends State<SendPage> {
  final List<FileWrapper> _recentFiles = [];

  bool _dragging = false;

  void _addRecentFile(FileWrapper fw) {
    setState(() {
      _recentFiles.removeWhere((e) => e.file.path == fw.file.path);
      _recentFiles.insert(0, fw);
      if (_recentFiles.length > 15) _recentFiles.removeLast();
    });
  }

  void _clearRecentFiles() => setState(_recentFiles.clear);

  /// Highlights the drop zone while files are dragged over the window.
  void setDragging(bool dragging) {
    if (dragging != _dragging) setState(() => _dragging = dragging);
  }

  /// Sends files dropped anywhere on the window.
  Future<void> sendDroppedFiles(List<DropItem> items) async {
    final files = await _copyDroppedFiles(items);
    if (files.isNotEmpty && mounted) await _showQrPages(files);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: context.useDesktopLayout
          ? null
          : AppBar(
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
      body: context.useDesktopLayout ? _buildDesktopBody() : _buildPhoneBody(),
    );
  }

  /// The send buttons in the middle, or with recents the buttons at the top
  /// and the recents list right under them.
  Widget _buildPhoneBody() {
    final buttons = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          _SendCard(
            icon: HugeIcons.strokeRoundedFileAdd,
            title: context.l10n.send_file,
            subtitle: context.l10n.send_file_subtitle,
            onTap: _pickFileToEncode,
          ),
          _photosCard(),
        ],
      ),
    );
    if (_recentFiles.isEmpty) return Center(child: buttons);
    // The scaffold body's padding covers the app bar and the bottom tabs,
    // which both overlap the page. The list runs on under the tabs.
    return Builder(
      builder: (context) {
        final padding = MediaQuery.paddingOf(context);
        return Padding(
          padding: EdgeInsets.only(top: padding.top),
          child: Column(
            children: [
              const SizedBox(height: 16),
              buttons,
              const SizedBox(height: 24),
              Expanded(
                child: RecentFilesTiles(
                  entries: _recentFiles,
                  bottomInset: padding.bottom,
                  onSend: _showQrPages,
                  onClear: _clearRecentFiles,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// The drop zone alone in the middle, or with recents the top two thirds
  /// of the page and the recents list the rest.
  Widget _photosCard() => _SendCard(
    icon: HugeIcons.strokeRoundedImageAdd01,
    title: context.l10n.send_picture,
    subtitle: context.l10n.send_picture_subtitle,
    flipIcon: true,
    onTap: _pickMediaToEncode,
  );

  Widget _buildDesktopBody() {
    final dropZone = DropZone(highlighted: _dragging, onTap: _pickFileToEncode);
    // Tablets and Android desktop mode keep the photo library, which the
    // file picker can't always reach.
    final photos = [
      if (!isDesktopOS) ...[const SizedBox(height: 8), _photosCard()],
    ];
    final unsupported = Text(context.l10n.desktop_receive_unsupported);
    if (_recentFiles.isEmpty) {
      return Column(
        children: [
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: SizedBox(
                width: _desktopContentWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 280, child: dropZone),
                    ...photos,
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: canScanWithCamera
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: unsupported,
                    ),
            ),
          ),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Center(
        child: SizedBox(
          width: _desktopContentWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 2, child: dropZone),
              ...photos,
              const SizedBox(height: 24),
              Expanded(
                child: RecentFilesList(
                  entries: _recentFiles,
                  onSend: _showQrPages,
                  onClear: _clearRecentFiles,
                ),
              ),
              if (!canScanWithCamera) ...[
                const SizedBox(height: 12),
                unsupported,
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _pickFileToEncode() => _send(pickFiles().then(_toFileWrappers));

  void _pickMediaToEncode() => _send(_pickMedia().then(_toFileWrappers));

  Future<List<File>> _pickMedia() async {
    final media = await ImagePicker().pickMultipleMedia();
    if (media.isEmpty) return const [];
    return _renamePickedMedia(media);
  }

  static Future<List<FileWrapper>> _toFileWrappers(List<File> files) =>
      Future.wait(files.map((f) => f.toFileWrapper()));

  /// On iOS the picker names files `image_picker_<UUID>`, so give them short
  /// camera-style names instead.
  Future<List<File>> _renamePickedMedia(List<XFile> media) async {
    if (!Platform.isIOS) return [for (final f in media) File(f.path)];
    final dir = await (await appTempDirectory()).createTemp('picked_');
    final stamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
    return Future.wait([
      for (final (i, f) in media.indexed)
        moveFile(
          File(f.path),
          '${dir.path}/IMG_$stamp${media.length > 1 ? '-${i + 1}' : ''}'
          '${p.extension(f.path)}',
        ),
    ]);
  }

  /// Dropped files are only readable during the drop (macOS sandbox access is
  /// scoped to it), so copy them somewhere the app can keep using.
  Future<List<File>> _copyDroppedFiles(List<DropItem> items) async {
    final dir = await (await appTempDirectory()).createTemp('dropped_');
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

  Future<void> _showQrPages(List<File> files) async {
    // Recent files can be deleted or moved by other apps.
    final exists = await Future.wait(files.map((f) => f.exists()));
    if (!mounted) return;
    final missing = [
      for (final (i, file) in files.indexed)
        if (!exists[i]) file,
    ];
    if (missing.isNotEmpty) {
      setState(() {
        _recentFiles.removeWhere(
          (fw) => missing.any((f) => f.path == fw.file.path),
        );
      });
      await showFileMissing(context, missing.first.uri.pathSegments.last);
      return;
    }
    final fileWrappers = await _toFileWrappers(files);
    if (mounted) await _send(SynchronousFuture(fileWrappers));
  }

  /// Opens the send sheet right away. Picked files arrive once the picker
  /// has copied them.
  Future<void> _send(Future<List<FileWrapper>> files) async {
    final chosen = await chooseFilesAndSendOptions(context, files);
    if (chosen == null || !mounted) return;

    await sendFiles(context, chosen.files, chosen.options);
    if (mounted) {
      for (final fw in chosen.files) {
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

const _desktopContentWidth = 720.0;

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
          color: context.cardFill,
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
                      height: 1,
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
              icon: context.isRtl
                  ? HugeIcons.strokeRoundedArrowLeft01
                  : HugeIcons.strokeRoundedArrowRight01,
              color: context.color.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
