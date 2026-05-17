import 'package:blast_qr/app_preferences.dart';
import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/features/settings/image_compression_settings_page.dart';
import 'package:blast_qr/features/settings/widgets/setting_group_title.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/image_compression_settings.dart';
import 'package:blast_qr/widgets/bottom_sheets.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

class SendSettingsPage extends StatefulWidget {
  const SendSettingsPage({super.key});

  @override
  State<SendSettingsPage> createState() => _SendSettingsPageState();
}

class _SendSettingsPageState extends State<SendSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sending')),
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
          const SettingGroupTitle(title: 'QR Codes'),
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
                    message:
                        '2935 bytes is the recommended value for best performance on most devices.',
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
          Consumer<EncodeSettings>(
            builder: (context, state, child) {
              return ListTile(
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedPlayList,
                  color: context.color.onSurface,
                ),
                title: Text(context.l10n.playback_fps),
                subtitle: Text('${state.playbackFps} FPS'),
                onTap: () {
                  showSliderSheet(
                    context,
                    title: context.l10n.playback_fps,
                    message:
                        '20 FPS is the recommended value for best performance on most devices.',
                    value: state.playbackFps,
                    min: 1,
                    max: 90,
                    onConfirm: (fps) {
                      Provider.of<EncodeSettings>(
                        context,
                        listen: false,
                      ).updatePlaybackFps(fps);
                    },
                  );
                },
              );
            },
          ),
          const SettingGroupTitle(title: 'Images'),
          ListTile(
            leading: HugeIcon(
              icon: HugeIcons.strokeRoundedImage01,
              color: context.color.onSurface,
            ),
            title: Text(context.l10n.image_compression),
            subtitle: Consumer<AppSettings>(
              builder: (context, state, child) {
                return Text(state.imageCompressionSettings.toString());
              },
            ),
            onTap: _showImageCompressionSettings,
          ),
        ],
      ),
    );
  }

  void _restoreDefaults() {
    final encodeSettings = Provider.of<EncodeSettings>(context, listen: false);
    encodeSettings.updateMtu(AppPreferences.defaultMtu);
    encodeSettings.updatePlaybackFps(20);
    Provider.of<AppSettings>(
      context,
      listen: false,
    ).updateImageCompressionSettings(ImageCompressionSettings.defaultSettings);
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
