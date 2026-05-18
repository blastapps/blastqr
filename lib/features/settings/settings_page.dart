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
  final _rightPaneKey = GlobalKey<NavigatorState>();
  int _selectedIndex = 0;

  static const _wideBreakpoint = 600.0;

  bool _isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= _wideBreakpoint;

  void _openDetail(BuildContext context, Widget page, int index) {
    if (_isWide(context)) {
      setState(() => _selectedIndex = index);
      _rightPaneKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => page),
        (_) => false,
      );
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    }
  }

  Widget _buildSettingsList(BuildContext context) {
    final appSettings = Provider.of<AppSettings>(context, listen: false);
    final wide = _isWide(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.of(context).padding.bottom,
      ),
      children: [
        ListTile(
          selected: wide && _selectedIndex == 1,
          leading: HugeIcon(
            icon: HugeIcons.strokeRoundedSent02,
            color: context.color.onSurface,
          ),
          title: Text(context.l10n.sending_settings),
          onTap: () => _openDetail(context, const SendSettingsPage(), 1),
          trailing: wide ? null : const Icon(Icons.chevron_right_rounded),
        ),
        ListTile(
          selected: wide && _selectedIndex == 2,
          leading: HugeIcon(
            icon: HugeIcons.strokeRoundedQrCode01,
            color: context.color.onSurface,
          ),
          title: Text(context.l10n.receiving_settings),
          onTap: () => _openDetail(context, const ReceivingSettingsPage(), 2),
          trailing: wide ? null : const Icon(Icons.chevron_right_rounded),
        ),
        ListTile(
          selected: wide && _selectedIndex == 0,
          leading: HugeIcon(
            icon: HugeIcons.strokeRoundedPaintBoard,
            color: context.color.onSurface,
          ),
          title: Text(context.l10n.appearance),
          onTap: () => _openDetail(context, const AppearancePage(), 0),
          trailing: wide ? null : const Icon(Icons.chevron_right_rounded),
        ),
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
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBottomContent(BuildContext context) {
    return Container(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isWide(context)) {
      return Scaffold(
        body: Row(
          children: [
            SizedBox(
              width: 280,
              child: Scaffold(
                appBar: AppBar(
                  title: Text(context.l10n.settings),
                  surfaceTintColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  leading: BackButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                bottomNavigationBar: SafeArea(
                  child: _buildBottomContent(context),
                ),
                body: _buildSettingsList(context),
              ),
            ),
            const VerticalDivider(width: 1, thickness: 0.25),
            Expanded(
              child: Navigator(
                key: _rightPaneKey,
                onGenerateRoute:
                    (_) => MaterialPageRoute(
                      builder: (_) => const SendSettingsPage(),
                    ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settings),
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBar: SafeArea(child: _buildBottomContent(context)),
      body: _buildSettingsList(context),
    );
  }
}
