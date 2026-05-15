import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/features/settings/image_compression_settings_page.dart';
import 'package:blast_qr/l10n/app_localizations.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/widgets/bottom_sheets.dart';
import 'package:blast_qr/widgets/logo_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
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
          0,
          16,
          0,
          MediaQuery.of(context).padding.bottom,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Text(
              context.l10n.language,
              style: TextStyle(
                color: context.color.primary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Text(
              context.l10n.appearance,
              style: TextStyle(
                color: context.color.primary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ListTile(
            leading: HugeIcon(
              icon: HugeIcons.strokeRoundedSun03,
              color: context.color.onSurface,
            ),
            title: Text(context.l10n.theme),
            subtitle: Text(
              ThemeOptions.values[appSettings.theme.index].title(context),
            ),
            onTap: () {
              showPickerSheet(
                context,
                title: context.l10n.theme,
                items: ThemeOptions.titles(context),
                onItemTap: (item) {
                  appSettings.updateTheme(ThemeOptions.values[item].themeMode);
                },
              );
            },
          ),
          Consumer<AppSettings>(
            builder: (context, state, child) {
              return ListTile(
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedColorPicker,
                  color: context.color.onSurface,
                ),
                title: Text(context.l10n.accent_color),
                trailing: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 2,
                        color: context.color.outline,
                      ),
                      shape: BoxShape.circle,
                      color: state.accentColor,
                    ),
                  ),
                ),
                onTap: () {
                  showSheet(
                    context: context,
                    title: context.l10n.accent_color,
                    body: _ColorPicker(
                      selectedColor: state.accentColor,
                      onPickColor: (color) {
                        appSettings.updateAccentColor(color);
                      },
                    ),
                  );
                },
              );
            },
          ),
          if (appSettings.theme != ThemeMode.light)
            Consumer<AppSettings>(
              builder: (context, state, child) {
                return SwitchListTile.adaptive(
                  value: state.pureBlack,
                  onChanged: (val) {
                    appSettings.updatePureBlackEnabled(val);
                  },
                  secondary: HugeIcon(
                    icon: HugeIcons.strokeRoundedGibbousMoon,
                    color: context.color.onSurface,
                  ),
                  title: Text(context.l10n.pure_black),
                  subtitle: Text(
                    state.pureBlack
                        ? context.l10n.enabled
                        : context.l10n.disabled,
                  ),
                  inactiveThumbColor: context.color.secondary,
                  activeTrackColor: context.color.primary,
                );
              },
            ),
          Consumer<AppSettings>(
            builder: (context, state, child) {
              return SwitchListTile.adaptive(
                value: state.animations,
                onChanged: (val) {
                  appSettings.updateAnimationsEnabled(val);
                },
                secondary: HugeIcon(
                  icon: HugeIcons.strokeRoundedStars,
                  color: context.color.onSurface,
                ),
                title: Text(context.l10n.animations),
                subtitle: Text(
                  state.animations
                      ? context.l10n.enabled
                      : context.l10n.disabled,
                ),
                inactiveThumbColor: context.color.secondary,
                activeTrackColor: context.color.primary,
              );
            },
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              context.l10n.behaviour,
              style: TextStyle(
                color: context.color.primary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Consumer<EncodeSettings>(
            builder: (context, state, child) {
              return ListTile(
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowDataTransferHorizontal,
                  color: context.color.onSurface,
                ),
                title: Text(context.l10n.chunk_length),
                subtitle: Text('${state.mtu} bytes'),
                onTap: () {
                  showSliderSheet(
                    context,
                    title: context.l10n.chunk_length,
                    message: context.l10n.chunk_length,
                    value: state.mtu,
                    min: 100,
                    max: 2935,
                    onConfirm: (mtu) {
                      Provider.of<EncodeSettings>(
                        context,
                        listen: false,
                      ).updateMtu(mtu);
                    },
                  );
                },
              );
            },
          ),
          ListTile(
            leading: HugeIcon(
              icon: HugeIcons.strokeRoundedImage01,
              color: context.color.onSurface,
            ),
            title: Text(context.l10n.image_compression_settings),
            onTap: _showImageCompressionSettings,
          ),
          Consumer<AppSettings>(
            builder: (context, state, child) {
              return ListTile(
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedCamera01,
                  color: context.color.onSurface,
                ),
                title: Text(context.l10n.camera_resolution),
                subtitle: Text(appSettings.cameraResolution.name),
                onTap: () {
                  showPickerSheet(
                    context,
                    title: context.l10n.camera_resolution,
                    items: ResolutionPreset.values.map((r) => r.name).toList(),
                    onItemTap: (index) {
                      appSettings.updateCameraResolution(
                        ResolutionPreset.values[index],
                      );
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              context.l10n.feedback,
              style: TextStyle(
                color: context.color.primary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Consumer<AppSettings>(
            builder: (context, state, child) {
              return SwitchListTile.adaptive(
                value: state.hapticFeedback,
                onChanged: (val) {
                  Provider.of<AppSettings>(
                    context,
                    listen: false,
                  ).updateHapticFeedback(val);
                },
                secondary: HugeIcon(
                  icon: HugeIcons.strokeRoundedSmartPhone03,
                  color: context.color.onSurface,
                ),
                title: Text(context.l10n.haptic_feedback),
                subtitle: Text(
                  state.hapticFeedback
                      ? context.l10n.enabled
                      : context.l10n.disabled,
                ),
                inactiveThumbColor: context.color.secondary,
                activeTrackColor: context.color.primary,
              );
            },
          ),
          Consumer<AppSettings>(
            builder: (context, state, child) {
              return SwitchListTile.adaptive(
                value: state.soundFeedback,
                onChanged: (val) {
                  Provider.of<AppSettings>(
                    context,
                    listen: false,
                  ).updateSoundFeedback(val);
                },
                secondary: HugeIcon(
                  icon: HugeIcons.strokeRoundedVolumeLow,
                  color: context.color.onSurface,
                ),
                title: Text(context.l10n.sound_feedback),
                subtitle: Text(
                  state.soundFeedback
                      ? context.l10n.enabled
                      : context.l10n.disabled,
                ),
                inactiveThumbColor: context.color.secondary,
                activeTrackColor: context.color.primary,
              );
            },
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              'blastqr',
              style: TextStyle(
                color: context.color.primary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
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

  void _showImageCompressionSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return const ImageCompressionSettingsPage();
        },
      ),
    );
  }
}

class _ColorPicker extends StatefulWidget {
  const _ColorPicker({required this.selectedColor, required this.onPickColor});

  final Color selectedColor;
  final void Function(Color color) onPickColor;

  @override
  State<_ColorPicker> createState() => __ColorPickerState();
}

enum ThemeOptions {
  system,
  light,
  dark;

  String title(BuildContext context) {
    switch (this) {
      case ThemeOptions.system:
        return context.l10n.theme_system;
      case ThemeOptions.light:
        return context.l10n.theme_light;
      case ThemeOptions.dark:
        return context.l10n.theme_dark;
    }
  }

  static List<String> titles(BuildContext context) {
    return [
      context.l10n.theme_system,
      context.l10n.theme_light,
      context.l10n.theme_dark,
    ];
  }

  ThemeMode get themeMode {
    switch (this) {
      case ThemeOptions.system:
        return ThemeMode.system;
      case ThemeOptions.light:
        return ThemeMode.light;
      case ThemeOptions.dark:
        return ThemeMode.dark;
    }
  }
}

class __ColorPickerState extends State<_ColorPicker> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.selectedColor;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height / 3,
      child: GridView.count(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        children:
            accentColorOptions.map((c) {
              final isSelected = c == _selectedColor;
              final outlineColor =
                  isSelected ? context.color.onSurface : context.color.outline;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = c;
                  });
                  widget.onPickColor(c);
                  Navigator.of(context).pop();
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: outlineColor, width: 3),
                    shape: BoxShape.circle,
                    color: c,
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
