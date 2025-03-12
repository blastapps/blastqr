import 'package:blast_qr/features/qr_page.dart';
import 'package:blast_qr/file_badge_count.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';

class PreviewPage extends StatefulWidget {
  const PreviewPage({super.key, required this.file, required this.time});

  final FileWrapper file;
  final String? time;

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${context.l10n.received_in} ${widget.time}'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        spacing: 8,
        children: [
          SizedBox(height: 32),
          GestureDetector(
            onTap: () {
              _onTapOpen(widget.file);
            },
            child: Container(
              width: 150,
              height: 150,
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
              child: widget.file.buildThumbnail(context),
            ),
          ),
          Text(widget.file.name),
          Spacer(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  spacing: 8,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          Provider.of<FileBadgeCount>(
                            context,
                            listen: false,
                          ).subtract();
                          await widget.file.file.delete();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: Text(context.l10n.discard),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(context.l10n.save),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
}
