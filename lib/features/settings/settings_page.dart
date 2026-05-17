import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/features/settings/appearance_page.dart';
import 'package:blast_qr/features/settings/receiving_settings_page.dart';
import 'package:blast_qr/features/settings/send_settings_page.dart';
import 'package:blast_qr/l10n/app_localizations.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/widgets/bottom_sheets.dart';
import 'package:blast_qr/widgets/logo_widget.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
          height: 90,
          child: Column(
            spacing: 4,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  showLicensePage(
                    applicationName: '',
                    applicationIcon: const LogoWidget(),
                    context: context,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                  child: Text(
                    context.l10n.licenses,
                    style: TextStyle(color: context.color.primary),
                  ),
                ),
              ),
              FutureBuilder(
                future: PackageInfo.fromPlatform(),
                builder: (context, s) {
                  if (s.hasData) {
                    return Text(
                      'blastQR version ${s.data?.version}.${s.data?.buildNumber}',
                    );
                  }
                  return const SizedBox();
                },
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
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
                    return const AppearancePage();
                  },
                ),
              );
            },
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
          ListTile(
            leading: HugeIcon(
              icon: HugeIcons.strokeRoundedSent02,
              color: context.color.onSurface,
            ),
            title: const Text('Sending'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return const SendSettingsPage();
                  },
                ),
              );
            },
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
          ListTile(
            leading: HugeIcon(
              icon: HugeIcons.strokeRoundedQrCode01,
              color: context.color.onSurface,
            ),
            title: const Text('Receiving'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return const ReceivingSettingsPage();
                  },
                ),
              );
            },
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
