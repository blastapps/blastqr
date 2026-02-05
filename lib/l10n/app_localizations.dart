import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ca.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ca'),
    Locale('en'),
    Locale('es'),
    Locale('ko'),
  ];

  /// No description provided for @blast_title.
  ///
  /// In en, this message translates to:
  /// **'BLAST'**
  String get blast_title;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @receive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get receive;

  /// No description provided for @my_files.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get my_files;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @pick_file_msg.
  ///
  /// In en, this message translates to:
  /// **'Pick a file to send'**
  String get pick_file_msg;

  /// No description provided for @keep_scanning_msg.
  ///
  /// In en, this message translates to:
  /// **'Keep scanning!'**
  String get keep_scanning_msg;

  /// No description provided for @result.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get result;

  /// No description provided for @file_name.
  ///
  /// In en, this message translates to:
  /// **'File name'**
  String get file_name;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @delete_msg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this file?'**
  String get delete_msg;

  /// No description provided for @yes_delete.
  ///
  /// In en, this message translates to:
  /// **'Yes, delete'**
  String get yes_delete;

  /// No description provided for @save_to_downloads.
  ///
  /// In en, this message translates to:
  /// **'Save to Downloads'**
  String get save_to_downloads;

  /// No description provided for @file_options.
  ///
  /// In en, this message translates to:
  /// **'File options'**
  String get file_options;

  /// No description provided for @no_files_msg.
  ///
  /// In en, this message translates to:
  /// **'No files yet.'**
  String get no_files_msg;

  /// No description provided for @saved_to.
  ///
  /// In en, this message translates to:
  /// **'Saved to'**
  String get saved_to;

  /// No description provided for @received_in.
  ///
  /// In en, this message translates to:
  /// **'Received in'**
  String get received_in;

  /// No description provided for @large_file.
  ///
  /// In en, this message translates to:
  /// **'Large file'**
  String get large_file;

  /// No description provided for @large_file_msg_1.
  ///
  /// In en, this message translates to:
  /// **'The file you selected is large and could take up to'**
  String get large_file_msg_1;

  /// No description provided for @large_file_msg_2.
  ///
  /// In en, this message translates to:
  /// **'to transfer.'**
  String get large_file_msg_2;

  /// No description provided for @large_file_msg_3.
  ///
  /// In en, this message translates to:
  /// **'Would you like to send a compresed, lower quality version of this image?'**
  String get large_file_msg_3;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @image_compression_settings.
  ///
  /// In en, this message translates to:
  /// **'Picture compression settings'**
  String get image_compression_settings;

  /// No description provided for @image_quality.
  ///
  /// In en, this message translates to:
  /// **'Image quality'**
  String get image_quality;

  /// No description provided for @send_large_file.
  ///
  /// In en, this message translates to:
  /// **'Send large file anyway'**
  String get send_large_file;

  /// No description provided for @send_compressed_image.
  ///
  /// In en, this message translates to:
  /// **'Send compressed image file'**
  String get send_compressed_image;

  /// No description provided for @to_transfer.
  ///
  /// In en, this message translates to:
  /// **'to transfer'**
  String get to_transfer;

  /// No description provided for @generating_codes.
  ///
  /// In en, this message translates to:
  /// **'Generating codes...'**
  String get generating_codes;

  /// No description provided for @send_help_message.
  ///
  /// In en, this message translates to:
  /// **'Scan this QR code using the blastQR app on the device where you want to receive the file.'**
  String get send_help_message;

  /// No description provided for @scan_help_message.
  ///
  /// In en, this message translates to:
  /// **'To receive a file, scan a QR code sequence from the screen of another device that uses blastQR.'**
  String get scan_help_message;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @help_title.
  ///
  /// In en, this message translates to:
  /// **'How to use blastQR'**
  String get help_title;

  /// No description provided for @help_title_1.
  ///
  /// In en, this message translates to:
  /// **'Get the blastQR app on other devices'**
  String get help_title_1;

  /// No description provided for @help_message_1_1.
  ///
  /// In en, this message translates to:
  /// **'Download the blastQR app on any device where you want to receive or send files. Both devices need to have the blastQR app.'**
  String get help_message_1_1;

  /// No description provided for @help_message_1_2.
  ///
  /// In en, this message translates to:
  /// **'Scan this QR code to download blastQR on another device. This particular code can be scanned using any regular QR code scanning app. blastQR is available for Android, iOS, Linux, macOS and Windows.'**
  String get help_message_1_2;

  /// No description provided for @help_title_2.
  ///
  /// In en, this message translates to:
  /// **'Sending a file'**
  String get help_title_2;

  /// No description provided for @help_message_2.
  ///
  /// In en, this message translates to:
  /// **'From the app\'s main screen, select the file or picture that you want to send.\n\nThe file will be encoded into a sequence of QR codes that you can then scan from another device that has blastQR installed.'**
  String get help_message_2;

  /// No description provided for @help_title_3.
  ///
  /// In en, this message translates to:
  /// **'Receiving a file'**
  String get help_title_3;

  /// No description provided for @help_message_3.
  ///
  /// In en, this message translates to:
  /// **'On another device, scan the QR code sequence using the blastQR app by selecting the \'Receive\' tab.\n\nThe files you receive are stored in the \'Received\' tab within the app.\n\nTIP: If the scanning process suddenly stops tap on the screen to resume.'**
  String get help_message_3;

  /// No description provided for @help_title_4.
  ///
  /// In en, this message translates to:
  /// **'Additional information'**
  String get help_title_4;

  /// No description provided for @help_message_4.
  ///
  /// In en, this message translates to:
  /// **'- blastQR file transfers work completely offline.\n\n- The transferred information is NOT encrypted and can be read by anyone who gains access to the QR code sequence. Avoid using blastQR for transmitting any sensitive information.\n\n- Due to the nature of the technology blastQR file transfers are slow (peaking at around 40kB/s). I recommend transferring small files or compressing them in advance.\n\n- For higher speeds play with the \'Chunk length\' setting in the Settings screen of the sending device. A higher value can result in higher speeds.\n\n- You can also use blastQR to scan regular QR codes.\n\n- blastQR is an open source project. You can find the source code at:'**
  String get help_message_4;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @theme_system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get theme_system;

  /// No description provided for @theme_light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get theme_light;

  /// No description provided for @theme_dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get theme_dark;

  /// No description provided for @pure_black.
  ///
  /// In en, this message translates to:
  /// **'Use pure black color'**
  String get pure_black;

  /// No description provided for @accent_color.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get accent_color;

  /// No description provided for @animations.
  ///
  /// In en, this message translates to:
  /// **'Animations'**
  String get animations;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @behaviour.
  ///
  /// In en, this message translates to:
  /// **'Behaviour'**
  String get behaviour;

  /// No description provided for @chunk_length.
  ///
  /// In en, this message translates to:
  /// **'Chunk length'**
  String get chunk_length;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licenses;

  /// No description provided for @file_format.
  ///
  /// In en, this message translates to:
  /// **'File format'**
  String get file_format;

  /// No description provided for @keep_original_file_format.
  ///
  /// In en, this message translates to:
  /// **'Keep original file format'**
  String get keep_original_file_format;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ca', 'en', 'es', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ca':
      return AppLocalizationsCa();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
