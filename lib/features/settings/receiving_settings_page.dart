import 'dart:io';
import 'dart:math';

import 'package:blast_qr/app_preferences.dart';
import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/extensions/string_extension.dart';
import 'package:blast_qr/features/scan/scan_camera.dart';
import 'package:blast_qr/features/settings/widgets/setting_group_title.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/widgets/bottom_sheets.dart';
import 'package:blast_qr/widgets/circle_button.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

class ReceivingSettingsPage extends StatefulWidget {
  const ReceivingSettingsPage({super.key});

  @override
  State<ReceivingSettingsPage> createState() => _ReceivingSettingsPageState();
}

const _zoomLevels = [1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0];

String _zoomLabel(double zoom) =>
    '${zoom == zoom.roundToDouble() ? zoom.toInt() : zoom}x';

class _ReceivingSettingsPageState extends State<ReceivingSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final appSettings = Provider.of<AppSettings>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.receiving_settings),
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
          // Linux scans at low resolution only, see ScanPage.
          if (!Platform.isLinux) ...[
            SettingGroupTitle(title: context.l10n.camera_section),
            Consumer<AppSettings>(
              builder: (context, state, child) {
                return ListTile(
                  leading: HugeIcon(
                    icon: HugeIcons.strokeRoundedCamera01,
                    color: context.color.onSurface,
                  ),
                  title: Text(context.l10n.camera_resolution),
                  subtitle: Text(
                    appSettings.cameraResolution.name.capitalize(),
                  ),
                  onTap: () {
                    showPickerSheet(
                      context,
                      selectedItemIndex: appSettings.cameraResolution.index,
                      title: context.l10n.camera_resolution,
                      message: context.l10n.camera_resolution_hint,
                      items: ResolutionPreset.values
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
            if (Platform.isIOS || Platform.isAndroid)
              Consumer<AppSettings>(
                builder: (context, state, child) {
                  return ListTile(
                    leading: HugeIcon(
                      icon: HugeIcons.strokeRoundedZoomInArea,
                      color: context.color.onSurface,
                    ),
                    title: Text(context.l10n.camera_zoom),
                    subtitle: Text(_zoomLabel(state.cameraZoom)),
                    onTap: () {
                      showPickerSheet(
                        context,
                        selectedItemIndex: _zoomLevels.indexOf(
                          state.cameraZoom,
                        ),
                        title: context.l10n.camera_zoom,
                        message: context.l10n.camera_zoom_hint,
                        items: _zoomLevels.map(_zoomLabel).toList(),
                        onItemTap: (index) {
                          state.updateCameraZoom(_zoomLevels[index]);
                        },
                      );
                    },
                  );
                },
              ),
            if (Platform.isIOS || Platform.isAndroid) const _FrameRateSetting(),
            if (Platform.isIOS || Platform.isAndroid)
              Consumer<AppSettings>(
                builder: (context, state, child) {
                  return SwitchListTile.adaptive(
                    contentPadding: const EdgeInsetsDirectional.only(start: 16),
                    value: state.cropCameraPreview,
                    onChanged: state.updateCropCameraPreview,
                    secondary: HugeIcon(
                      icon: HugeIcons.strokeRoundedCrop,
                      color: context.color.onSurface,
                    ),
                    title: Text(context.l10n.crop_camera_preview),
                    subtitle: Text(context.l10n.crop_camera_preview_hint),
                    activeTrackColor: context.color.primary,
                  );
                },
              ),
            if (Platform.isIOS) const _AdvancedCameraSettings(),
          ],
          SettingGroupTitle(title: context.l10n.feedback),

          Consumer<AppSettings>(
            builder: (context, state, child) {
              return SwitchListTile.adaptive(
                contentPadding: const EdgeInsetsDirectional.only(start: 16),
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
                activeTrackColor: context.color.primary,
              );
            },
          ),
          Consumer<AppSettings>(
            builder: (context, state, child) {
              return SwitchListTile.adaptive(
                contentPadding: const EdgeInsetsDirectional.only(start: 16),
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
                activeTrackColor: context.color.primary,
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
        final appSettings = Provider.of<AppSettings>(context, listen: false);
        appSettings.updateCameraResolution(
          AppPreferences.defaultCameraResolution,
        );
        appSettings.updateCameraFps(null);
        appSettings.updateCameraZoom(AppPreferences.defaultCameraZoom);
        appSettings.updateCropCameraPreview(false);
        appSettings.updateDebugVideoHdr(false);
        appSettings.updateDebugExposureMs(null);
        appSettings.updateHapticFeedback(false);
        appSettings.updateSoundFeedback(true);
      },
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

/// iPhone camera settings for comparing against the defaults: video HDR off
/// and exposure capped at [ScanCamera.defaultMaxExposureMs].
class _AdvancedCameraSettings extends StatelessWidget {
  const _AdvancedCameraSettings();

  static const _exposures = <double?>[null, 0, 4, 3, 2, 1, 0.5];

  static String _label(BuildContext context, double? ms) => switch (ms) {
    null => context.l10n.exposure_auto_capped(
      '${ScanCamera.defaultMaxExposureMs}',
    ),
    0 => context.l10n.exposure_auto,
    final ms => context.l10n.exposure_fixed('$ms'),
  };

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    return ExpansionTile(
      tilePadding: const EdgeInsetsDirectional.only(start: 16),
      shape: const Border(),
      leading: HugeIcon(
        icon: HugeIcons.strokeRoundedSettings02,
        color: context.color.onSurface,
      ),
      title: Text(context.l10n.advanced),
      children: [
        SwitchListTile.adaptive(
          contentPadding: const EdgeInsetsDirectional.only(start: 16),
          title: Text(context.l10n.allow_video_hdr),
          subtitle: Text(context.l10n.allow_video_hdr_hint),
          value: settings.debugVideoHdr,
          onChanged: settings.updateDebugVideoHdr,
          activeTrackColor: context.color.primary,
        ),
        ListTile(
          title: Text(context.l10n.exposure_time),
          subtitle: Text(_label(context, settings.debugExposureMs)),
          onTap: () => showPickerSheet(
            context,
            title: context.l10n.exposure_time,
            message: context.l10n.exposure_time_hint,
            selectedItemIndex: _exposures.indexOf(settings.debugExposureMs),
            items: [for (final ms in _exposures) _label(context, ms)],
            onItemTap: (i) => settings.updateDebugExposureMs(_exposures[i]),
          ),
        ),
      ],
    );
  }
}

/// The camera frame rates this phone offers at the current resolution.
class _FrameRateSetting extends StatefulWidget {
  const _FrameRateSetting();

  @override
  State<_FrameRateSetting> createState() => _FrameRateSettingState();
}

class _FrameRateSettingState extends State<_FrameRateSetting> {
  ResolutionPreset? _resolution;
  Future<List<int>>? _rates;

  String _label(BuildContext context, int? fps, List<int> rates) {
    if (fps != null) return '$fps FPS';
    final auto = rates.where((r) => r <= ScanCamera.maxAutoFps);
    return auto.isEmpty
        ? context.l10n.fps_default
        : context.l10n.fps_auto('${auto.reduce(max)}');
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    if (settings.cameraResolution != _resolution) {
      _resolution = settings.cameraResolution;
      _rates = ScanCamera.supportedFrameRates(settings.cameraResolution);
    }
    return FutureBuilder(
      future: _rates,
      builder: (context, snapshot) {
        final rates = snapshot.data ?? const <int>[];
        final options = <int?>[null, ...rates];
        return ListTile(
          leading: HugeIcon(
            icon: HugeIcons.strokeRoundedDashboardSpeed02,
            color: context.color.onSurface,
          ),
          title: Text(context.l10n.camera_fps),
          subtitle: Text(_label(context, settings.cameraFps, rates)),
          onTap: () => showPickerSheet(
            context,
            title: context.l10n.camera_fps,
            message: context.l10n.camera_fps_hint,
            selectedItemIndex: options.indexOf(settings.cameraFps),
            items: [for (final fps in options) _label(context, fps, rates)],
            onItemTap: (i) => settings.updateCameraFps(options[i]),
          ),
        );
      },
    );
  }
}
