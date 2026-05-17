import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/extensions/string_extension.dart';
import 'package:blast_qr/features/settings/widgets/setting_group_title.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/widgets/bottom_sheets.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

class ReceivingSettingsPage extends StatefulWidget {
  const ReceivingSettingsPage({super.key});

  @override
  State<ReceivingSettingsPage> createState() => _ReceivingSettingsPageState();
}

class _ReceivingSettingsPageState extends State<ReceivingSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final appSettings = Provider.of<AppSettings>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: const Text('Receiving')),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          height: 56,
          child: OutlinedButton(
            onPressed: _restoreDefaults,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                Text('Restore'),
                HugeIcon(icon: HugeIcons.strokeRoundedUndo),
              ],
            ),
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
          const SettingGroupTitle(title: 'Camera'),
          Consumer<AppSettings>(
            builder: (context, state, child) {
              return ListTile(
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedCamera01,
                  color: context.color.onSurface,
                ),
                title: Text(context.l10n.camera_resolution),
                subtitle: Text(appSettings.cameraResolution.name.capitalize()),
                onTap: () {
                  showPickerSheet(
                    context,
                    title: context.l10n.camera_resolution,
                    message:
                        'Most devices will perform better with this setting set to "High"',
                    items:
                        ResolutionPreset.values
                            .map((r) => r.name.capitalize())
                            .toList(),
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
          SettingGroupTitle(title: context.l10n.feedback),
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
        ],
      ),
    );
  }

  void _restoreDefaults() {
    final appSettings = Provider.of<AppSettings>(context, listen: false);
    appSettings.updateCameraResolution(ResolutionPreset.high);
    appSettings.updateHapticFeedback(false);
    appSettings.updateSoundFeedback(true);
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
