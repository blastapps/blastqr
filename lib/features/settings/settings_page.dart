import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/features/settings/behaviour_page.dart';
import 'package:blast_qr/features/settings/lang_appearance_page.dart';
import 'package:blast_qr/features/settings/widgets/setting_group_title.dart';
import 'package:blast_qr/l10n/app_localizations.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/widgets/bottom_sheets.dart';
import 'package:blast_qr/widgets/logo_widget.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final appSettings = Provider.of<AppSettings>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settings),
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).padding.bottom,
        ),
        children: [
          ListTile(
            leading: HugeIcon(
              icon: HugeIcons.strokeRoundedLanguageSkill,
              color: context.color.onSurface,
            ),
            title: Text(context.l10n.language),
            subtitle: Text(
              languageNames[AppLocalizations.of(context)?.localeName] ?? '',
            ),
            onTap: () {
              showPickerSheet(
                context,
                title: context.l10n.language,
                items: languageNames.values.toList(),
                onItemTap: (item) {
                  appSettings.updateLocale(
                    AppLocalizations.supportedLocales[item].languageCode,
                  );
                },
              );
            },
          ),
          ListTile(
            leading: HugeIcon(
              icon: HugeIcons.strokeRoundedPaintBoard,
              color: context.color.onSurface,
            ),
            title: Text(context.l10n.appearance),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return const LangAppearancePage();
                  },
                ),
              );
            },
            trailing: Icon(Icons.adaptive.arrow_forward_rounded, size: 16),
          ),
          ListTile(
            leading: HugeIcon(
              icon: HugeIcons.strokeRoundedSettings04,
              color: context.color.onSurface,
            ),
            title: Text(context.l10n.behaviour),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return const BehaviourPage();
                  },
                ),
              );
            },
            trailing: Icon(Icons.adaptive.arrow_forward_rounded, size: 16),
          ),
          const SizedBox(height: 16),
          const SettingGroupTitle(title: 'blastQR'),
          ListTile(
            leading: HugeIcon(
              icon: HugeIcons.strokeRoundedLicense,
              color: context.color.onSurface,
            ),
            title: Text(context.l10n.licenses),
            onTap: () {
              showLicensePage(
                applicationName: '',
                applicationIcon: const LogoWidget(),
                context: context,
              );
            },
          ),
          ListTile(
            leading: HugeIcon(
              icon: HugeIcons.strokeRoundedCode,
              color: context.color.onSurface,
            ),
            title: const Text('v1.0.1'),
          ),
        ],
      ),
    );
  }
}
