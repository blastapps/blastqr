import 'dart:io';

import 'package:blast_qr/model/file_wrapper.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:blast_qr/features/qr_page.dart';

class SendPage extends StatefulWidget {
  const SendPage({super.key});

  @override
  State<SendPage> createState() => _SendPageState();
}

class _SendPageState extends State<SendPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: SizedBox(
          height: 180,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _pickFileToEncode,
            child: Text('Pick a file to send'),
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

  void _showQrPage(File file) async {
    final fileWrapper = await file.toFileWrapper();
    if (mounted) {
      Navigator.of(context).push(
        CupertinoSheetRoute(
          builder: (context) {
            return QrPage(file: fileWrapper);
          },
        ),
      );
    }
  }
}
