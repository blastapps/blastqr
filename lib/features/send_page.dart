import 'dart:io';

import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/features/help_page.dart';
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
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          spacing: 16,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _pickFileToEncode,
              child: Container(
                padding: EdgeInsets.all(16),
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
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            OutlinedButton(
              onPressed: _onTapHelp,
              style: OutlinedButton.styleFrom(minimumSize: Size(0, 48)),
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
                children: [
                  Text(
                    '* Receiving files is not supported on the desktop app yet.',
                  ),
                ],
              ),
          ],
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
        (Platform.isIOS || Platform.isAndroid)
            ? CupertinoSheetRoute(
              builder: (context) {
                return QrPage(file: fileWrapper);
              },
            )
            : MaterialPageRoute(
              fullscreenDialog: true,
              builder: (context) {
                return QrPage(file: fileWrapper);
              },
            ),
      );
    }
  }

  void _onTapHelp() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) {
          return HelpPage();
        },
      ),
    );
  }
}
