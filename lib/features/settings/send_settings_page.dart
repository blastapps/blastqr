import 'package:blast_qr/acoustic_ack_listener.dart';
import 'package:blast_qr/app_preferences.dart';
import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/features/settings/image_compression_settings_page.dart';
import 'package:blast_qr/features/settings/widgets/setting_group_title.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/image_compression_settings.dart';
import 'package:blast_qr/model/video_quality.dart';
import 'package:blast_qr/widgets/bottom_sheets.dart';
import 'package:blast_qr/widgets/circle_button.dart';
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
      appBar: AppBar(
        title: Text(context.l10n.sending_settings),
        actions: [
          CircleButton(
            onPressed: _restoreDefaults,
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedUndo),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.of(context).padding.bottom,
        ),
        children: [
          SettingGroupTitle(title: context.l10n.qr_codes_section),

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
                    message: context.l10n.chunk_length_hint,
                    value: state.mtu,
                    min: 100,
                    max: 2935,
                    defaultValue: AppPreferences.defaultMtu,
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
                    message: context.l10n.playback_fps_hint,
                    value: state.playbackFps,
                    min: 1,
                    max: 90,
                    defaultValue: AppPreferences.defaultFps,
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
          Consumer<EncodeSettings>(
            builder: (context, state, child) {
              return SwitchListTile.adaptive(
                contentPadding: const EdgeInsetsDirectional.only(start: 16),
                secondary: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowExpand,
                  color: context.color.onSurface,
                ),
                title: Text(context.l10n.multi_qr_mode),
                subtitle: Text(context.l10n.multi_qr_mode_subtitle),
                value: state.multipleQrCodes,
                activeTrackColor: context.color.primary,
                onChanged: (value) {
                  Provider.of<EncodeSettings>(
                    context,
                    listen: false,
                  ).updateMultipleQrCodes(value);
                },
              );
            },
          ),
          SettingGroupTitle(title: context.l10n.acoustic_feedback),
          Consumer<AppSettings>(
            builder: (context, state, child) {
              return SwitchListTile.adaptive(
                contentPadding: const EdgeInsetsDirectional.only(start: 16),
                secondary: HugeIcon(
                  icon: HugeIcons.strokeRoundedAudioWave01,
                  color: context.color.onSurface,
                ),
                title: Text(context.l10n.acoustic_detection),
                subtitle: Text(context.l10n.acoustic_detection_subtitle),
                value: state.acousticDetection,
                activeTrackColor: context.color.primary,
                onChanged: (value) async {
                  final appSettings = Provider.of<AppSettings>(
                    context,
                    listen: false,
                  );
                  if (value) {
                    final granted =
                        await AcousticAckListener.requestPermission();
                    if (!mounted || !granted) return;
                  }
                  appSettings.updateAcousticDetection(value);
                },
              );
            },
          ),
          SettingGroupTitle(title: context.l10n.photos_and_videos_section),
          Consumer<AppSettings>(
            builder: (context, state, child) {
              return SwitchListTile.adaptive(
                contentPadding: const EdgeInsetsDirectional.only(start: 16),
                title: Text(context.l10n.compress_media_by_default),
                subtitle: Text(
                  context.l10n.compress_media_by_default_subtitle,
                ),
                value: state.compressMediaByDefault,
                activeTrackColor: context.color.primary,
                onChanged: (value) {
                  Provider.of<AppSettings>(
                    context,
                    listen: false,
                  ).updateCompressMediaByDefault(value);
                },
              );
            },
          ),
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
          Consumer<AppSettings>(
            builder: (context, state, child) {
              return ListTile(
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedVideo01,
                  color: context.color.onSurface,
                ),
                title: Text(context.l10n.video_quality),
                subtitle: Text(state.videoQuality.title(context.l10n)),
                onTap: () => showPickerSheet(
                  context,
                  title: context.l10n.video_quality,
                  message: context.l10n.video_quality_hint,
                  items: [
                    for (final quality in VideoQuality.values)
                      quality.title(context.l10n),
                  ],
                  selectedItemIndex: state.videoQuality.index,
                  onItemTap: (index) =>
                      state.updateVideoQuality(VideoQuality.values[index]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _restoreDefaults() {
    showMessage(
      context: context,
      title: context.l10n.restore_defaults,
      message: context.l10n.restore_defaults_msg,
      confirmTitle: context.l10n.restore_defaults,
      secondaryTitle: context.l10n.cancel,
      onConfirmTap: () {
        final encodeSettings = Provider.of<EncodeSettings>(
          context,
          listen: false,
        );
        encodeSettings.updateMtu(AppPreferences.defaultMtu);
        encodeSettings.updatePlaybackFps(AppPreferences.defaultFps);
        encodeSettings.updateMultipleQrCodes(false);
        Provider.of<AppSettings>(context, listen: false)
          ..updateImageCompressionSettings(
            ImageCompressionSettings.defaultSettings,
          )
          ..updateVideoQuality(AppPreferences.defaultVideoQuality);
      },
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
        children: accentColorOptions.map((c) {
          final isSelected = c == _selectedColor;
          final outlineColor = isSelected
              ? context.color.onSurface
              : context.color.outline;
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
