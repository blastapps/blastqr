import 'dart:io';

import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/features/files_received/received_items.dart';
import 'package:blast_qr/features/files_received/save_to_downloads.dart';
import 'package:blast_qr/features/files_received/widgets/file_options_sheet.dart';
import 'package:blast_qr/features/files_received/widgets/qr_code_sheet.dart';
import 'package:blast_qr/features/send/prepare_transfer.dart';
import 'package:blast_qr/features/send/send_files.dart';
import 'package:blast_qr/features/send/send_options.dart';
import 'package:blast_qr/features/send/widgets/custom_password_sheet.dart';
import 'package:blast_qr/features/send/widgets/hd_toggle.dart';
import 'package:blast_qr/file_name_utils.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blast_qr/platform_support.dart';
import 'package:blast_qr/reveal_in_file_manager.dart';
import 'package:blast_qr/widgets/bottom_sheets.dart';
import 'package:blast_qr/widgets/centered_with_trailing.dart';
import 'package:blast_qr/widgets/file_list_selection.dart';
import 'package:blast_qr/widgets/file_preview.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

/// What can be done with received items: the options dialogs, and opening,
/// renaming, deleting, saving and sending them.
mixin ReceivedItemActions<T extends StatefulWidget> on State<T> {
  FileListSelection<ReceivedItem> get selection;

  /// Loads the list again after files were changed.
  Future<void> reloadItems();

  /// Desktop: the options for one item, or for the whole selection.
  void openItems(List<ReceivedItem> items) {
    if (items.length > 1) {
      _showMultiSelectSheet();
    } else if (items.singleOrNull case final item?) {
      showItemOptions(item);
    }
  }

  void showItemOptions(ReceivedItem item) {
    switch (item) {
      case ReceivedFile(:final file):
        showFileOptionsSheet(
          context,
          file,
          onOpen: () => _onTapOpen(file),
          onShare: isDesktopOS ? null : (origin) => _onTapShare(file, origin),
          onShowInFileManager: isDesktopOS
              ? () => _onTapShowInFileManager(file.file)
              : null,
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

  Future<void> _onTapShare(FileWrapper file, Rect origin) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.file.path, mimeType: file.type.mimeType)],
          sharePositionOrigin: origin,
        ),
      );
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _onTapShowInFileManager(File file) async {
    Navigator.of(context).pop();
    try {
      await revealInFileManager(file);
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _showMultiSelectSheet() async {
    final files = await Future.wait(
      selection.selected.map((item) => item.toFileWrapper()),
    );
    if (!mounted) return;
    final hd = ValueNotifier(
      !Provider.of<AppSettings>(context, listen: false).compressMediaByDefault,
    );
    final showsHd = files.any(isCompressibleMedia);
    showSheet(
      context: context,
      title: context.l10n.files_selected(files.length),
      body: Column(
        children: [
          CenteredWithTrailing(
            trailing: showsHd ? HdToggle(hd: hd) : null,
            child: FilesPreview(files: files, maxShown: showsHd ? 3 : 4),
          ),
          const SizedBox(height: 8),
          SendTile(
            onTap: () {
              Navigator.of(context).pop();
              _sendSelectedFiles(files, plainSend(compressMedia: !hd.value));
            },
          ),
          SendEncryptedTile(
            onTap: () {
              Navigator.of(context).pop();
              _sendSelectedFiles(
                files,
                encryptedSend(compressMedia: !hd.value),
              );
            },
            onLongPress: () async {
              Navigator.of(context).pop();
              final password = await showCustomPasswordSheet(context);
              if (password == null || !mounted) return;
              _sendSelectedFiles(files, (
                password: password,
                fileName: null,
                compressMedia: !hd.value,
              ));
            },
          ),
          if (Platform.isAndroid)
            ListTile(
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
    selection.clear();
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
      selection.clear();
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
        await reloadItems();
        if (mounted) selection.clear();
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
      await reloadItems();
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
      await reloadItems();
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  void _showError(Object error) => _showSnackBar(error.toString());

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, textAlign: TextAlign.center)),
    );
  }
}
