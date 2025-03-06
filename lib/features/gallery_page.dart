import 'dart:io';
import 'dart:math';
import 'package:blast_qr/features/collection_page.dart';
import 'package:blast_qr/features/qr_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:blast_qr/widgets/bottom_sheets.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key, required this.index});

  final int index;

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final PageController _pageController = PageController();
  final String _fileSize = '';

  bool _immersiveMode = false;
  int _currentItem = 0;

  List<FileSystemEntity>? _imageFiles;

  @override
  void initState() {
    super.initState();
    _currentItem = widget.index;

    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar:
          _immersiveMode
              ? null
              : AppBar(
                title: const Text(''),
                actions: [
                  IconButton(
                    onPressed: _onTapDelete,
                    icon: const Icon(Icons.delete),
                  ),
                  IconButton(
                    onPressed: _onTapSend,
                    icon: const Icon(Icons.qr_code),
                  ),
                ],
              ),
      body: PhotoViewGallery.builder(
        pageController: _pageController,
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (BuildContext context, int index) {
          final file = _imageFiles![index] as File;
          return PhotoViewGalleryPageOptions(
            imageProvider: _provideImage(file),
            heroAttributes: PhotoViewHeroAttributes(tag: file.hashCode),
            onTapDown: (context, details, controllerValue) {
              _toggleImmersiveMode();
            },
          );
        },
        itemCount: _imageFiles?.length ?? 0,
        loadingBuilder:
            (context, event) => Center(
              child: SizedBox(
                width: 20.0,
                height: 20.0,
                child: CircularProgressIndicator(
                  value:
                      event == null
                          ? 0
                          : event.cumulativeBytesLoaded /
                              (event.expectedTotalBytes ?? 1),
                ),
              ),
            ),
      ),
    );
  }

  void _toggleImmersiveMode() {
    _immersiveMode = !_immersiveMode;
    if (_immersiveMode) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    setState(() {});
  }

  Future<void> _loadItems() async {
    final directory = await getApplicationDocumentsDirectory();
    final itemsDirectory = Directory('${directory.path}/treasures');

    if (await itemsDirectory.exists()) {
      final List<FileSystemEntity> files = itemsDirectory.listSync();
      setState(() {
        _imageFiles = files.whereType<File>().toList(); // Filter to only files
      });
    } else {
      setState(() {
        _imageFiles = []; // No images found
      });
    }

    _pageController.jumpToPage(widget.index);
  }

  Future<void> _onTapDelete() async {
    showSheet(
      context: context,
      title: 'Delete',
      body: Column(
        spacing: 4,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Are you sure you want to delete this file?'),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _deleteFile,
            child: const Text('Yes, delete'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFile() async {
    try {
      await _imageFiles?[_currentItem].delete();
    } catch (error) {
      if (mounted) {
        final snackBar = SnackBar(content: Text(error.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
    if (mounted) {
      Navigator.of(context).pop();
      Navigator.of(context).pop(true);
    }
  }

  void _onTapSend() async {
    if (_imageFiles == null || _imageFiles?.isEmpty == true) {
      return;
    }
    final file = _imageFiles![_currentItem] as File;
    final fileSizeInBytes = await file.length();
    if (mounted) {
      Navigator.of(context).push(
        CupertinoSheetRoute(
          builder: (context) {
            return QrPage(file: file, fileSizeInBytes: fileSizeInBytes);
          },
        ),
      );
    }
  }

  ImageProvider? _provideImage(File file) {
    final avifImage = FileAvifImage(file);
    return avifImage;
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
}

extension FileSizeExtension on File {
  Future<String> fileSize({int decimals = 1}) async {
    int bytes = await length();
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }
}
