import 'dart:io';

import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/features/settings_page.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blast_qr/widgets/logo_widget.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:blast_qr/features/qr_page.dart';
import 'package:hugeicons/hugeicons.dart';

class SendPage extends StatefulWidget {
  const SendPage({super.key});

  @override
  State<SendPage> createState() => _SendPageState();
}

class _SendPageState extends State<SendPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: LogoWidget(),
        centerTitle: true,
        toolbarHeight: 80,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return SettingsPage();
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _pickFileToEncode,
            child: Container(
              height: 240,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: context.color.outline, width: 1),
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
              child: Text(
                context.l10n.pick_file_msg,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
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
