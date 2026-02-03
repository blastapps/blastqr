import 'package:blast_qr/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

extension BuildContextHelper on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

const languageNames = {
  'ca': 'Català',
  'en': 'English',
  'es': 'Español',
  'ko': '한국어',
};
