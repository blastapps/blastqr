import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/image_compression_settings.dart';
import 'package:blast_qr/widgets/bottom_sheets.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

class ImageCompressionSettingsPage extends StatefulWidget {
  const ImageCompressionSettingsPage({super.key});

  @override
  State<ImageCompressionSettingsPage> createState() =>
      _ImageCompressionSettingsPageState();
}

class _ImageCompressionSettingsPageState
    extends State<ImageCompressionSettingsPage> {
  static int downscaleCutoff = 999999;

  ImageCompressionOutputFormat? _outputFormat;
  int? _quality;
  late int _minSize;

  bool get downscalingEnabled => _minSize < downscaleCutoff;

  @override
  void initState() {
    super.initState();
    final appSettings = Provider.of<AppSettings>(context, listen: false);
    _outputFormat = appSettings.imageCompressionSettings.outputFormat;
    _quality = appSettings.imageCompressionSettings.quality;
    _minSize = appSettings.imageCompressionSettings.minSize;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.image_compression)),
      body: Consumer<AppSettings>(
        builder: (context, appSettings, child) {
          final settings = appSettings.imageCompressionSettings;
          return ListView(
            children: [
              ListTile(
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedFileManagement,
                  color: context.color.onSurface,
                ),
                title: Text(context.l10n.file_format),
                subtitle: Text(settings.outputFormat.title(context.l10n)),
                onTap: () {
                  showPickerSheet(
                    context,
                    title: context.l10n.file_format,
                    items: ImageCompressionOutputFormat.titles(context.l10n),
                    onItemTap: (index) {
                      _outputFormat =
                          ImageCompressionOutputFormat.values[index];
                      _buildAndUpdateSettings();
                    },
                  );
                },
              ),
              ListTile(
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedImageComposition,
                  color: context.color.onSurface,
                ),
                title: Text(context.l10n.image_quality),
                subtitle: Text('${settings.quality}%'),
                onTap: () {
                  showSliderSheet(
                    context,
                    title: context.l10n.image_quality,
                    value: settings.quality,
                    min: 0,
                    max: 100,
                    defaultValue:
                        ImageCompressionSettings.defaultSettings.quality,
                    onConfirm: (val) {
                      _quality = val;
                      _buildAndUpdateSettings();
                    },
                  );
                },
              ),
              SwitchListTile.adaptive(
                title: Text(context.l10n.downscaling),
                value: downscalingEnabled,
                activeTrackColor: context.color.primary,
                onChanged: (enabled) {
                  setState(() {
                    _minSize =
                        enabled
                            ? ImageCompressionSettings.defaultSettings.minSize
                            : downscaleCutoff;
                    _buildAndUpdateSettings();
                  });
                },
              ),
              if (downscalingEnabled)
                ListTile(
                  leading: HugeIcon(
                    icon: HugeIcons.strokeRoundedSquareArrowShrink02,
                    color: context.color.onSurface,
                  ),
                  title: Text(context.l10n.downscaling),
                  subtitle: Text(
                    context.l10n.downscaling_subtitle(
                      settings.minSize.toString(),
                    ),
                  ),
                  onTap: () {
                    showTextInputSheet(
                      context,
                      title: context.l10n.downscaling,
                      hintText: context.l10n.downscaling,
                      prefilledText: settings.minSize.toString(),
                      keyboardType: const TextInputType.numberWithOptions(),
                      onConfirm: (val) {
                        _validateMinSize(val);
                        _buildAndUpdateSettings();
                      },
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  void _validateMinSize(String val) {
    var minSize =
        int.tryParse(val) ?? ImageCompressionSettings.defaultSettings.minSize;
    if (minSize < 100) {
      showMessage(
        context: context,
        title: context.l10n.error,
        message: context.l10n.invalid_downscale_value,
      );
      minSize = ImageCompressionSettings.defaultSettings.minSize;
    }
    _minSize = minSize;
  }

  void _buildAndUpdateSettings() {
    final appSettings = Provider.of<AppSettings>(context, listen: false);

    final defaults = ImageCompressionSettings.defaultSettings;
    final settings = ImageCompressionSettings(
      outputFormat: _outputFormat ?? defaults.outputFormat,
      quality: _quality ?? defaults.quality,
      minSize: _minSize,
    );

    appSettings.updateImageCompressionSettings(settings);
  }
}
