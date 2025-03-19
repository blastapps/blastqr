import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/theme.dart';
import 'package:blast_qr/widgets/bottom_sheets.dart';
import 'package:blast_qr/widgets/logo_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
      appBar: AppBar(title: Text(context.l10n.settings)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Text(context.l10n.appearance),
          ),
          ListTile(
            title: Text(context.l10n.language),
            subtitle: Text(AppLocalizations.of(context)?.localeName ?? ''),
            onTap: () {
              showPickerSheet(
                context,
                title: context.l10n.language,
                items:
                    AppLocalizations.supportedLocales
                        .map((l) => l.toLanguageTag())
                        .toList(),
                onItemTap: (item) {
                  appSettings.updateLocale(
                    AppLocalizations.supportedLocales[item].languageCode,
                  );
                },
              );
            },
          ),
          ListTile(
            title: Text(context.l10n.theme),
            subtitle: Text(appSettings.theme.title(context)),
            onTap: () {
              showPickerSheet(
                context,
                title: context.l10n.theme,
                items: BlastTheme.titles(context),
                onItemTap: (item) {
                  appSettings.updateTheme(BlastTheme.values[item]);
                },
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(context.l10n.data_encoding),
          ),
          Consumer<EncodeSettings>(
            builder: (context, state, child) {
              return ListTile(
                title: Text('Chunk length'),
                subtitle: Text(state.mtu.toString()),
                onTap: () {
                  showTextInputSheet(
                    context,
                    title: 'Chunk length',
                    hintText: 'A number around 900 works best.',
                    prefilledText: state.mtu.toString(),
                    keyboardType: TextInputType.numberWithOptions(),
                    onConfirm: _validateMtu,
                  );
                },
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text('blastqr'),
          ),
          ListTile(
            title: Text(context.l10n.licenses),
            onTap: () {
              showLicensePage(
                applicationName: '',
                applicationIcon: LogoWidget(),
                context: context,
              );
            },
          ),
          ListTile(title: Text('v0.01')),
        ],
      ),
    );
  }

  void _validateMtu(String val) {
    final mtu = int.tryParse(val) ?? 924;
    Provider.of<EncodeSettings>(context, listen: false).updateMtu(mtu);
  }
}
