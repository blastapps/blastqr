import 'dart:io';

import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/features/qr_page.dart';
import 'package:blast_qr/file_badge_count.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blast_qr/widgets/bottom_sheets.dart';
import 'package:blast_qr/widgets/logo_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

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
        ..sort(
          (l, r) =>
              r.file.statSync().modified.compareTo(l.file.statSync().modified),
        ); // Filter to only files
    } else {
      _files = []; // No images found
    }
    _isLoading = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: LogoWidget(),
        centerTitle: true,
        toolbarHeight: 80,
        surfaceTintColor: Colors.transparent,
      ),
      body: Builder(
        builder: (context) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
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
          return ListView.builder(
            itemCount: _files.length,
            itemBuilder: (context, index) {
              final file = _files[index];
              return ListTile(
                onTap: () {
                  _onTapItem(file);
                },
                leading: Container(
                  width: 56,
                  height: 56,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(60),
                        spreadRadius: 0,
                        blurRadius: 2,
                        offset: Offset(0, 2),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: file.buildThumbnail(context),
                ),
                title: Text(file.name),
                subtitle: Text(file.sizeInkB),
              );
            },
          );
        },
      ),
    );
  }

  void _onTapItem(FileWrapper file) {
    showSheet(
      context: context,
      title: context.l10n.file_options,
      body: Column(
        spacing: 8,
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
                    offset: Offset(0, 2),
                  ),
                ],
                borderRadius: BorderRadius.circular(12),
              ),
              child: file.buildThumbnail(context, showsAvifThumbnail: true),
            ),
          ),
          Text(file.name),
          SizedBox(height: 8),
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
          SizedBox(height: 8),
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
      CupertinoSheetRoute(
        builder: (context) {
          return QrPage(file: file);
        },
      ),
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
      final directory = Directory('/storage/emulated/0/Download');
      final newPath =
          '${directory.path}/${newName ?? file.uri.pathSegments.last}';
      await file.copy(newPath);

      if (mounted) {
        Navigator.of(context).pop();
        final snackBar = SnackBar(
          content: Text("${context.l10n.saved_to} $newPath"),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (error) {
      if (error is PathExistsException) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final nameComps = file.uri.pathSegments.last.split('.');
        final name = nameComps.elementAtOrNull(0);
        final ext = nameComps.elementAtOrNull(1);
        _trySaveToDownloads(
          file,
          newName: '${name ?? 'file'}_$timestamp.${ext ?? 'bin'}',
        );
      } else {
        if (mounted) {
          Navigator.of(context).pop();
          final snackBar = SnackBar(content: Text(error.toString()));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      }
    }
  }
}
