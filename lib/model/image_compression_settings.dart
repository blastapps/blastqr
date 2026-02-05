import 'dart:convert';

import 'package:blast_qr/l10n/app_localizations.dart';

class ImageCompressionSettings {
  final ImageCompressionOutputFormat outputFormat;
  final int quality;
  final int minSize;

  const ImageCompressionSettings({
    required this.outputFormat,
    required this.quality,
    required this.minSize,
  });

  static ImageCompressionSettings defaultSettings =
      const ImageCompressionSettings(
        outputFormat: ImageCompressionOutputFormat.keepOriginal,
        quality: 80,
        minSize: 2048,
      );

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'outputFormat': outputFormat.name,
      'quality': quality,
      'minSize': minSize,
    };
  }

  factory ImageCompressionSettings.fromMap(Map<String, dynamic> map) {
    return ImageCompressionSettings(
      outputFormat:
          map['outputFormat'] != null
              ? ImageCompressionOutputFormat.values.byName(map['outputFormat'])
              : ImageCompressionOutputFormat.keepOriginal,
      quality: map['quality'] as int,
      minSize: map['minSize'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory ImageCompressionSettings.fromJson(String source) =>
      ImageCompressionSettings.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  static ImageCompressionSettings? parseSafely(String? json) {
    if (json == null) {
      return ImageCompressionSettings.defaultSettings;
    }
    try {
      return ImageCompressionSettings.fromJson(json);
    } catch (e) {
      return ImageCompressionSettings.defaultSettings;
    }
  }
}

enum ImageCompressionOutputFormat {
  keepOriginal,
  jpeg,
  heic,
  webp;

  String title(AppLocalizations loc) {
    switch (this) {
      case ImageCompressionOutputFormat.keepOriginal:
        return 'Keep original file format';
      case ImageCompressionOutputFormat.jpeg:
        return name.toUpperCase();
      case ImageCompressionOutputFormat.heic:
        return name.toUpperCase();
      case ImageCompressionOutputFormat.webp:
        return name.toUpperCase();
    }
  }

  static List<String> titles(AppLocalizations loc) {
    return values.map((i) => i.title(loc)).toList();
  }
}
