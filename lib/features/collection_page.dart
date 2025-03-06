import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:path_provider/path_provider.dart';
import 'package:blast_qr/features/gallery_page.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key, this.onPickFile});

  final void Function(File? file)? onPickFile;

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  List<FileSystemEntity>? _imageFiles;

  @override
  void initState() {
    super.initState();
    _loadItems();
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
  }

  @override
  Widget build(BuildContext context) {
    final cacheWidth =
        (MediaQuery.of(context).devicePixelRatio) *
        ((MediaQuery.of(context).size.width / 2) - 64);
    return Scaffold(
      body:
          _imageFiles == null
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Adjust the number of columns here
                  childAspectRatio:
                      1, // Adjust the aspect ratio of the grid items
                ),
                itemCount: _imageFiles!.length,
                itemBuilder: (context, index) {
                  final file = _imageFiles![index] as File;
                  return GestureDetector(
                    onTap: () => _onTapItem(index),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.file(
                        file,
                        fit: BoxFit.cover,
                        cacheWidth: cacheWidth.toInt(),
                        errorBuilder:
                            (a, b, c) => AvifImage.file(
                              file,
                              fit: BoxFit.cover,
                              cacheWidth: cacheWidth.toInt(),
                            ),
                      ),
                    ),
                  );
                },
              ),
    );
  }

  void _onTapItem(int index) {
    if (widget.onPickFile != null) {
      Navigator.of(context).pop();
      final file = _imageFiles?.elementAtOrNull(index) as File?;
      widget.onPickFile!(file);
      return;
    }
    Navigator.of(context)
        .push<bool>(
          MaterialPageRoute(
            builder: (context) {
              return GalleryPage(index: index);
            },
          ),
        )
        .then((shouldReload) {
          if (shouldReload == true) {
            _loadItems();
          }
        });
  }
}
