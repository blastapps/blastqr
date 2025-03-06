import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class PreviewPage extends StatefulWidget {
  const PreviewPage({super.key, required this.data, required this.time});

  final Uint8List data;
  final String? time;

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Result: ${widget.time}'),
        actions: [
          IconButton(onPressed: _tryToSave, icon: const Icon(Icons.save)),
        ],
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(100),
              minScale: 0.5,
              maxScale: 8,
              child: _buildImage(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
            child: ElevatedButton(
              onPressed: _onTapOpen,
              child: Text('Open file'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return Image.memory(
      widget.data,
      errorBuilder: (context, error, stackTrace) {
        return AvifImage.memory(
          widget.data,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          fit: BoxFit.contain,
        );
      },
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      fit: BoxFit.contain,
    );
  }

  Future<void> _tryToSave() async {
    try {
      await _saveToCollection();
      const snackBar = SnackBar(content: Text('Saved successfully!'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (error) {
      final snackBar = SnackBar(content: Text('Error: ${error.toString()}'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  Future<void> _saveToCollection() async {
    final directory = await getApplicationDocumentsDirectory();
    final itemsDirectory = Directory('${directory.path}/treasures');

    if (await itemsDirectory.exists() == false) {
      await itemsDirectory.create();
    }

    final millis = DateTime.now().millisecondsSinceEpoch;
    final file = await File(
      '${itemsDirectory.path}/$millis-item.txqrfile',
    ).writeAsBytes(widget.data);

    log('Saved to: ${file.path}');
  }

  void _onTapOpen() async {
    final directory = await getApplicationCacheDirectory();
    final tempDir = Directory('${directory.path}/temp');

    if (await tempDir.exists() == false) {
      await tempDir.create();
    }

    final millis = DateTime.now().millisecondsSinceEpoch;
    final file = await File(
      '${tempDir.path}/$millis-item.p8.png',
    ).writeAsBytes(widget.data);

    OpenFile.open(file.path, type: "image/png");
  }
}
