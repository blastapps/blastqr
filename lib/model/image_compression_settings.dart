import 'dart:convert';

import 'package:blast_qr/l10n/app_localizations.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

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
        outputFormat: ImageCompressionOutputFormat.jpeg,
        quality: 75,
        minSize: 1536,
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
              : defaultSettings.outputFormat,
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

  @override
  String toString() {
    if (minSize < 999999) {
      return '${outputFormat.name.toUpperCase()} | $quality% | ${minSize}px';
    }
    return '${outputFormat.name.toUpperCase()} | $quality%';
  }
}

enum ImageCompressionOutputFormat {
  jpeg,
  heic;

  CompressFormat toCompressFormat() {
    switch (this) {
      case ImageCompressionOutputFormat.jpeg:
        return CompressFormat.jpeg;
      case ImageCompressionOutputFormat.heic:
        return CompressFormat.heic;
    }
  }

  String title(AppLocalizations loc) {
    switch (this) {
      case ImageCompressionOutputFormat.jpeg:
        return name.toUpperCase();
      case ImageCompressionOutputFormat.heic:
        return name.toUpperCase();
    }
  }

  String? get extension {
    switch (this) {
      case ImageCompressionOutputFormat.jpeg:
        return 'jpg';
      case ImageCompressionOutputFormat.heic:
        return 'heic';
    }
  }

  static List<String> titles(AppLocalizations loc) {
    return values.map((i) => i.title(loc)).toList();
  }
}
