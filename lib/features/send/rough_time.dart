import 'dart:math';

/// [seconds] as an estimate: whole minutes, rounded up, from a minute on,
/// and below that seconds rounded up to 5, so the label doesn't change on
/// every update.
String roughTime(
  int seconds, {
  required String Function(int seconds) inSeconds,
  required String Function(int minutes) inMinutes,
}) => seconds < 60
    ? inSeconds(max(5, (seconds + 4) ~/ 5 * 5))
    : inMinutes((seconds / 60).ceil());
