import 'dart:io';

import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/features/help/help_page.dart';
import 'package:blast_qr/features/settings/appearance_page.dart';
import 'package:blast_qr/features/settings/debug_page.dart';
import 'package:blast_qr/features/settings/files_settings_page.dart';
import 'package:blast_qr/features/settings/receiving_settings_page.dart';
import 'package:blast_qr/features/settings/send_settings_page.dart';
import 'package:blast_qr/l10n/app_localizations.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/platform_support.dart';
import 'package:blast_qr/widgets/bottom_sheets.dart';
import 'package:blast_qr/widgets/logo_widget.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _rightPaneKey = GlobalKey<NavigatorState>();
  int _selectedIndex = 1;

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

  static const _tileShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );

  Widget _detailTile(
    BuildContext context, {
    required int index,
    required List<List<dynamic>> icon,
    required String title,
    required Widget page,
  }) {
    final wide = _isWide(context);
    final selected = wide && _selectedIndex == index;
    return ListTile(
      selected: selected,
      selectedTileColor: context.color.primaryContainer,
      shape: _tileShape,
      leading: HugeIcon(
        icon: icon,
        color: selected ? context.color.primary : context.color.onSurface,
      ),
      title: Text(title),
      onTap: () => _openDetail(context, page, index),
      trailing: wide ? null : const Icon(Icons.chevron_right_rounded),
    );
  }

  Widget _buildSettingsList(BuildContext context) {
    final appSettings = Provider.of<AppSettings>(context, listen: false);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.of(context).padding.bottom,
      ),
      children: [
        ListTile(
          shape: _tileShape,
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
        _detailTile(
          context,
          index: 0,
          icon: HugeIcons.strokeRoundedPaintBoard,
          title: context.l10n.appearance,
          page: const AppearancePage(),
        ),
        _detailTile(
          context,
          index: 1,
          icon: HugeIcons.strokeRoundedSent02,
          title: context.l10n.sending_settings,
          page: const SendSettingsPage(),
        ),
        _detailTile(
          context,
          index: 2,
          icon: HugeIcons.strokeRoundedQrCode01,
          title: context.l10n.receiving_settings,
          page: const ReceivingSettingsPage(),
        ),
        if (Platform.isIOS)
          _detailTile(
            context,
            index: 5,
            icon: HugeIcons.strokeRoundedFolder01,
            title: context.l10n.files_settings,
            page: const FilesSettingsPage(),
          ),
        _detailTile(
          context,
          index: 3,
          icon: HugeIcons.strokeRoundedHelpCircle,
          title: context.l10n.help,
          page: const HelpPage(),
        ),
        if (canScanWithCamera)
          _detailTile(
            context,
            index: 4,
            icon: HugeIcons.strokeRoundedBug02,
            title: context.l10n.debug,
            page: const DebugPage(),
          ),
        Builder(
          builder: (tileContext) => ListTile(
            shape: _tileShape,
            leading: HugeIcon(
              icon: HugeIcons.strokeRoundedShare08,
              color: context.color.onSurface,
            ),
            title: Text(context.l10n.share_app),
            onTap: () {
              final box = tileContext.findRenderObject() as RenderBox?;
              SharePlus.instance.share(
                ShareParams(
                  text: HelpPage.projectUrl,
                  sharePositionOrigin: box == null
                      ? null
                      : box.localToGlobal(Offset.zero) & box.size,
                ),
              );
            },
          ),
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
          Row(
            spacing: 8,
            children: [
              GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse(HelpPage.projectUrl),
                  mode: LaunchMode.externalApplication,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                  child: Text(
                    context.l10n.source_code,
                    style: TextStyle(color: context.color.primary),
                  ),
                ),
              ),
              const Text('·'),
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
            ],
          ),
          FutureBuilder(
            future: PackageInfo.fromPlatform(),
            builder: (context, s) {
              if (s.hasData) {
                return Text('blastQR version ${s.data?.version}');
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
              width: 260,
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
                onGenerateRoute: (_) =>
                    MaterialPageRoute(builder: (_) => const SendSettingsPage()),
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
