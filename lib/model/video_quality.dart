import 'package:blast_qr/l10n/app_localizations.dart';

/// What videos are compressed to when sending without HD.
enum VideoQuality {
  original,
  low,
  lowest,
  potato;

  /// The video bitrate to aim for, or null when videos are sent as they
  /// are. 540p looks fine on a phone and at about 1 Mbps sends in about real
  /// time; 360p at 400 kbps sends more than twice as fast; 240p at 15 fps
  /// halves that again, for when only what happens matters.
  int? get videoBitrate => switch (this) {
    original => null,
    low => 1000000,
    lowest => 400000,
    potato => 200000,
  };

  /// Frames beyond this rate are dropped. Fewer frames leave more of the
  /// bitrate for each one.
  int get frameRate => this == potato ? 15 : 30;

  int get audioBitrate => this == potato ? 32000 : 64000;

  /// Mono is enough for speech at a low bitrate.
  int get audioChannels => this == potato ? 1 : 2;

  String title(AppLocalizations l10n) => switch (this) {
    original => l10n.video_quality_original,
    low => l10n.video_quality_low,
    lowest => l10n.video_quality_lowest,
    potato => l10n.video_quality_potato,
  };
}
