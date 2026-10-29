import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

class FilesSettingsPage extends StatelessWidget {
  const FilesSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.files_settings)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.of(context).padding.bottom,
        ),
        children: [
          SwitchListTile.adaptive(
            contentPadding: const EdgeInsetsDirectional.only(start: 16),
            value: settings.showInFilesApp,
            onChanged: settings.updateShowInFilesApp,
            secondary: HugeIcon(
              icon: HugeIcons.strokeRoundedFolder01,
              color: context.color.onSurface,
            ),
            title: Text(context.l10n.show_in_files_app),
            subtitle: Text(context.l10n.show_in_files_app_hint),
            activeTrackColor: context.color.primary,
          ),
        ],
      ),
    );
  }
}
