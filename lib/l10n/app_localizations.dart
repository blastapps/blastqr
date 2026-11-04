import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
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
    Locale('ar'),
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

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @show_in_file_manager.
  ///
  /// In en, this message translates to:
  /// **'See in file manager'**
  String get show_in_file_manager;

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
  /// **'Long transfer'**
  String get large_file;

  /// No description provided for @large_file_msg_1.
  ///
  /// In en, this message translates to:
  /// **'This transfer is large and could take up to'**
  String get large_file_msg_1;

  /// No description provided for @large_file_msg_2.
  ///
  /// In en, this message translates to:
  /// **'to transfer.'**
  String get large_file_msg_2;

  /// No description provided for @large_file_msg_3.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Would you like to send a compressed, lower quality version of this image?} other{Would you like to send compressed, lower quality versions of these {count} images?}}'**
  String large_file_msg_3(int count);

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @image_compression.
  ///
  /// In en, this message translates to:
  /// **'Image compression'**
  String get image_compression;

  /// No description provided for @image_quality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get image_quality;

  /// No description provided for @send_large_file.
  ///
  /// In en, this message translates to:
  /// **'Send anyway'**
  String get send_large_file;

  /// No description provided for @send_compressed_image.
  ///
  /// In en, this message translates to:
  /// **'Send compressed'**
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
  /// **'Scan this QR code using the blastQR app on the device where you want to receive the file'**
  String get send_help_message;

  /// No description provided for @scan_help_message.
  ///
  /// In en, this message translates to:
  /// **'To receive a file, scan a compatible QR code sequence'**
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
  /// **'- blastQR file transfers work completely offline.\n\n- The transferred information is NOT encrypted and can be read by anyone who gains access to the QR code sequence unless using the \'Send password-encrypted\' feature. Avoid using blastQR for transmitting any sensitive information without enabling encryption first and always use strong passwords.\n\n- Due to the nature of the technology, blastQR file transfers are not very fast by default. However, showing multiple codes at once (full-screen button) and raising the \'Playback speed\' in Settings can increase the speed dramatically.\n\n- You can also use blastQR to scan regular QR codes.\n\n- blastQR is an open source project. You can find the source code at:'**
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
  /// **'Animated background'**
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

  /// No description provided for @chunk_length.
  ///
  /// In en, this message translates to:
  /// **'QR code size'**
  String get chunk_length;

  /// No description provided for @playback_fps.
  ///
  /// In en, this message translates to:
  /// **'Playback speed'**
  String get playback_fps;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licenses;

  /// No description provided for @source_code.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get source_code;

  /// No description provided for @share_app.
  ///
  /// In en, this message translates to:
  /// **'Share blastQR'**
  String get share_app;

  /// No description provided for @file_format.
  ///
  /// In en, this message translates to:
  /// **'File format'**
  String get file_format;

  /// No description provided for @downscaling.
  ///
  /// In en, this message translates to:
  /// **'Downscaling'**
  String get downscaling;

  /// No description provided for @camera_resolution.
  ///
  /// In en, this message translates to:
  /// **'Camera preview resolution'**
  String get camera_resolution;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @haptic_feedback.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback'**
  String get haptic_feedback;

  /// No description provided for @sound_feedback.
  ///
  /// In en, this message translates to:
  /// **'Sound feedback'**
  String get sound_feedback;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @filter_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filter_all;

  /// No description provided for @filter_images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get filter_images;

  /// No description provided for @filter_videos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get filter_videos;

  /// No description provided for @filter_audio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get filter_audio;

  /// No description provided for @filter_document.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get filter_document;

  /// No description provided for @filter_book.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get filter_book;

  /// No description provided for @filter_other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get filter_other;

  /// No description provided for @older.
  ///
  /// In en, this message translates to:
  /// **'Older'**
  String get older;

  /// No description provided for @select_all.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get select_all;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get selected;

  /// No description provided for @delete_files_msg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the selected files?'**
  String get delete_files_msg;

  /// No description provided for @files_selected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file selected} other{{count} files selected}}'**
  String files_selected(int count);

  /// No description provided for @file_missing.
  ///
  /// In en, this message translates to:
  /// **'File not found'**
  String get file_missing;

  /// No description provided for @file_missing_msg.
  ///
  /// In en, this message translates to:
  /// **'{name} was moved or deleted.'**
  String file_missing_msg(String name);

  /// No description provided for @file_too_large.
  ///
  /// In en, this message translates to:
  /// **'File too large'**
  String get file_too_large;

  /// No description provided for @file_too_large_msg.
  ///
  /// In en, this message translates to:
  /// **'This file exceeds the 4 GB limit and cannot be sent.'**
  String get file_too_large_msg;

  /// No description provided for @low_speed_warning.
  ///
  /// In en, this message translates to:
  /// **'Low transfer speed. Adjust the position of the devices and keep them still for better performance'**
  String get low_speed_warning;

  /// No description provided for @send_file.
  ///
  /// In en, this message translates to:
  /// **'Send files'**
  String get send_file;

  /// No description provided for @send_picture.
  ///
  /// In en, this message translates to:
  /// **'Send photos & videos'**
  String get send_picture;

  /// No description provided for @send_file_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Any file type'**
  String get send_file_subtitle;

  /// No description provided for @send_picture_subtitle.
  ///
  /// In en, this message translates to:
  /// **'From your photo library'**
  String get send_picture_subtitle;

  /// No description provided for @drop_files.
  ///
  /// In en, this message translates to:
  /// **'Drop files here'**
  String get drop_files;

  /// No description provided for @drop_files_subtitle.
  ///
  /// In en, this message translates to:
  /// **'or click to choose'**
  String get drop_files_subtitle;

  /// No description provided for @desktop_receive_unsupported.
  ///
  /// In en, this message translates to:
  /// **'* Receiving files is not supported on Windows yet'**
  String get desktop_receive_unsupported;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @sending_settings.
  ///
  /// In en, this message translates to:
  /// **'Sending'**
  String get sending_settings;

  /// No description provided for @receiving_settings.
  ///
  /// In en, this message translates to:
  /// **'Receiving'**
  String get receiving_settings;

  /// No description provided for @restore_defaults.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore_defaults;

  /// No description provided for @reset_to_default.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get reset_to_default;

  /// No description provided for @restore_defaults_msg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to restore these settings to their default values?'**
  String get restore_defaults_msg;

  /// No description provided for @qr_codes_section.
  ///
  /// In en, this message translates to:
  /// **'QR Codes'**
  String get qr_codes_section;

  /// No description provided for @chunk_length_hint.
  ///
  /// In en, this message translates to:
  /// **'2935 bytes is the recommended value for best performance on most devices'**
  String get chunk_length_hint;

  /// No description provided for @playback_fps_hint.
  ///
  /// In en, this message translates to:
  /// **'20 FPS is the recommended value for best performance on most devices'**
  String get playback_fps_hint;

  /// No description provided for @multi_qr_mode.
  ///
  /// In en, this message translates to:
  /// **'Start in fullscreen'**
  String get multi_qr_mode;

  /// No description provided for @multi_qr_mode_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Show as many codes as fit on screen for a speed boost'**
  String get multi_qr_mode_subtitle;

  /// No description provided for @images_section.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get images_section;

  /// No description provided for @always_compress_images.
  ///
  /// In en, this message translates to:
  /// **'Always compress images'**
  String get always_compress_images;

  /// No description provided for @always_compress_images_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Images are compressed before sending'**
  String get always_compress_images_subtitle;

  /// No description provided for @camera_section.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera_section;

  /// No description provided for @camera_resolution_hint.
  ///
  /// In en, this message translates to:
  /// **'Most devices will perform better with this setting set to \"High\"'**
  String get camera_resolution_hint;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @invalid_downscale_value.
  ///
  /// In en, this message translates to:
  /// **'Invalid value (must be larger than 100)'**
  String get invalid_downscale_value;

  /// No description provided for @downscaling_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Downscaling to {size}px'**
  String downscaling_subtitle(String size);

  /// No description provided for @acoustic_detection.
  ///
  /// In en, this message translates to:
  /// **'Detect completion tone'**
  String get acoustic_detection;

  /// No description provided for @acoustic_detection_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Use microphone to detect when a file transfer has finished'**
  String get acoustic_detection_subtitle;

  /// No description provided for @acoustic_feedback.
  ///
  /// In en, this message translates to:
  /// **'Transfer completion tone'**
  String get acoustic_feedback;

  /// No description provided for @transfer_complete.
  ///
  /// In en, this message translates to:
  /// **'Transfer complete!'**
  String get transfer_complete;

  /// No description provided for @keep_showing_qr.
  ///
  /// In en, this message translates to:
  /// **'Show QR code again'**
  String get keep_showing_qr;

  /// No description provided for @mic_permission_title.
  ///
  /// In en, this message translates to:
  /// **'Auto-detect completion'**
  String get mic_permission_title;

  /// No description provided for @mic_permission_message.
  ///
  /// In en, this message translates to:
  /// **'blastQR can detect when a transfer has finished by listening for a completion tone through the microphone. Would you like to enable this feature?'**
  String get mic_permission_message;

  /// No description provided for @mic_permission_allow.
  ///
  /// In en, this message translates to:
  /// **'Allow microphone access'**
  String get mic_permission_allow;

  /// No description provided for @receive_failed_msg.
  ///
  /// In en, this message translates to:
  /// **'The file could not be saved. It may be damaged or larger than 4 GB.'**
  String get receive_failed_msg;

  /// No description provided for @file_too_large_for_qr_size_msg.
  ///
  /// In en, this message translates to:
  /// **'This file is too large for the current QR code size. Increase the QR code size in Settings › Sending.'**
  String get file_too_large_for_qr_size_msg;

  /// No description provided for @receiving_generic.
  ///
  /// In en, this message translates to:
  /// **'Receiving file...'**
  String get receiving_generic;

  /// No description provided for @update_required_title.
  ///
  /// In en, this message translates to:
  /// **'Update needed'**
  String get update_required_title;

  /// No description provided for @update_required_msg.
  ///
  /// In en, this message translates to:
  /// **'This was sent with a newer version of blastQR. Update the app to receive it.'**
  String get update_required_msg;

  /// No description provided for @sender_update_required_msg.
  ///
  /// In en, this message translates to:
  /// **'This was sent with an older version of blastQR. Ask the sender to update the app.'**
  String get sender_update_required_msg;

  /// No description provided for @send_encrypted.
  ///
  /// In en, this message translates to:
  /// **'Send password-encrypted'**
  String get send_encrypted;

  /// No description provided for @receiving_encrypted.
  ///
  /// In en, this message translates to:
  /// **'Receiving encrypted file...'**
  String get receiving_encrypted;

  /// No description provided for @enter_password.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enter_password;

  /// No description provided for @enter_password_msg.
  ///
  /// In en, this message translates to:
  /// **'This file is encrypted. Enter the password from the sender.'**
  String get enter_password_msg;

  /// No description provided for @wrong_password.
  ///
  /// In en, this message translates to:
  /// **'Wrong password. Try again.'**
  String get wrong_password;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @received_encrypted.
  ///
  /// In en, this message translates to:
  /// **'Received encrypted'**
  String get received_encrypted;

  /// No description provided for @show_password.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get show_password;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @new_password.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get new_password;

  /// No description provided for @edit_password.
  ///
  /// In en, this message translates to:
  /// **'Edit password'**
  String get edit_password;

  /// No description provided for @password_short_warning.
  ///
  /// In en, this message translates to:
  /// **'Use at least {min} characters.'**
  String password_short_warning(int min);

  /// No description provided for @custom_password_title.
  ///
  /// In en, this message translates to:
  /// **'Custom password'**
  String get custom_password_title;

  /// No description provided for @custom_password_msg.
  ///
  /// In en, this message translates to:
  /// **'The file will be encrypted with the following password.'**
  String get custom_password_msg;

  /// No description provided for @files_count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file} other{{count} files}}'**
  String files_count(int count);

  /// No description provided for @sending_files_count.
  ///
  /// In en, this message translates to:
  /// **'Sending {count} files'**
  String sending_files_count(int count);

  /// No description provided for @debug.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get debug;

  /// No description provided for @camera_zoom.
  ///
  /// In en, this message translates to:
  /// **'Camera zoom'**
  String get camera_zoom;

  /// No description provided for @camera_zoom_hint.
  ///
  /// In en, this message translates to:
  /// **'Zooming in lets the camera read codes from further away, where it can still focus. Helps on phones that can\'t focus up close.'**
  String get camera_zoom_hint;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @allow_video_hdr.
  ///
  /// In en, this message translates to:
  /// **'Allow video HDR'**
  String get allow_video_hdr;

  /// No description provided for @allow_video_hdr_hint.
  ///
  /// In en, this message translates to:
  /// **'Off by default. HDR can blend two codes into one frame.'**
  String get allow_video_hdr_hint;

  /// No description provided for @exposure_time.
  ///
  /// In en, this message translates to:
  /// **'Exposure time'**
  String get exposure_time;

  /// No description provided for @exposure_time_hint.
  ///
  /// In en, this message translates to:
  /// **'Long exposures blend two codes into one frame when the sender changes code mid-capture. A fixed exposure raises ISO to keep the brightness, so the image gets noisier.'**
  String get exposure_time_hint;

  /// No description provided for @exposure_auto_capped.
  ///
  /// In en, this message translates to:
  /// **'Automatic, max {ms} ms (default)'**
  String exposure_auto_capped(String ms);

  /// No description provided for @exposure_auto.
  ///
  /// In en, this message translates to:
  /// **'Automatic, no limit'**
  String get exposure_auto;

  /// No description provided for @exposure_fixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed {ms} ms'**
  String exposure_fixed(String ms);

  /// No description provided for @camera_fps.
  ///
  /// In en, this message translates to:
  /// **'Camera FPS'**
  String get camera_fps;

  /// No description provided for @camera_fps_hint.
  ///
  /// In en, this message translates to:
  /// **'Higher rates give the scanner more chances to read each code. Only the rates this phone supports at the current resolution are listed.'**
  String get camera_fps_hint;

  /// No description provided for @fps_default.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get fps_default;

  /// No description provided for @fps_auto.
  ///
  /// In en, this message translates to:
  /// **'Highest available ({fps} FPS)'**
  String fps_auto(String fps);

  /// No description provided for @debug_share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get debug_share;

  /// No description provided for @debug_clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get debug_clear;

  /// No description provided for @debug_camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get debug_camera;

  /// No description provided for @debug_device.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get debug_device;

  /// No description provided for @debug_supported_frame_rates.
  ///
  /// In en, this message translates to:
  /// **'Supported FPS'**
  String get debug_supported_frame_rates;

  /// No description provided for @debug_save_frames.
  ///
  /// In en, this message translates to:
  /// **'Save sample frames'**
  String get debug_save_frames;

  /// No description provided for @debug_save_frames_hint.
  ///
  /// In en, this message translates to:
  /// **'Keeps a few camera frames per transfer, to look at or share.'**
  String get debug_save_frames_hint;

  /// No description provided for @debug_last_transfers.
  ///
  /// In en, this message translates to:
  /// **'Last transfers'**
  String get debug_last_transfers;

  /// No description provided for @debug_no_transfers.
  ///
  /// In en, this message translates to:
  /// **'No transfers yet'**
  String get debug_no_transfers;

  /// No description provided for @debug_transfers_hint.
  ///
  /// In en, this message translates to:
  /// **'The last 5 transfers, kept in memory. Sharing includes every detail. Useful codes are ones read for the first time.'**
  String get debug_transfers_hint;

  /// No description provided for @debug_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get debug_unavailable;

  /// No description provided for @debug_status_receiving.
  ///
  /// In en, this message translates to:
  /// **'Receiving'**
  String get debug_status_receiving;

  /// No description provided for @debug_status_complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get debug_status_complete;

  /// No description provided for @debug_status_stopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get debug_status_stopped;

  /// No description provided for @debug_useful_codes.
  ///
  /// In en, this message translates to:
  /// **'Useful codes'**
  String get debug_useful_codes;

  /// No description provided for @debug_codes_caught.
  ///
  /// In en, this message translates to:
  /// **'Codes caught'**
  String get debug_codes_caught;

  /// No description provided for @debug_codes_caught_value.
  ///
  /// In en, this message translates to:
  /// **'{caught} of {shown} shown ({percent})'**
  String debug_codes_caught_value(int caught, int shown, String percent);

  /// No description provided for @debug_camera_value.
  ///
  /// In en, this message translates to:
  /// **'{fps} FPS · {percent} frames with a code'**
  String debug_camera_value(String fps, String percent);

  /// No description provided for @debug_decode.
  ///
  /// In en, this message translates to:
  /// **'Decode'**
  String get debug_decode;

  /// No description provided for @debug_decode_value.
  ///
  /// In en, this message translates to:
  /// **'{average} avg · {p95} p95'**
  String debug_decode_value(String average, String p95);

  /// No description provided for @debug_exposure.
  ///
  /// In en, this message translates to:
  /// **'Exposure'**
  String get debug_exposure;

  /// No description provided for @debug_frame_codes.
  ///
  /// In en, this message translates to:
  /// **'{read} of {max} codes read'**
  String debug_frame_codes(int read, int max);

  /// No description provided for @debug_frame_code_read.
  ///
  /// In en, this message translates to:
  /// **'code read'**
  String get debug_frame_code_read;

  /// No description provided for @debug_frame_no_code.
  ///
  /// In en, this message translates to:
  /// **'no code read'**
  String get debug_frame_no_code;

  /// No description provided for @debug_sample_frames_multi.
  ///
  /// In en, this message translates to:
  /// **'Sample frames (red: fewer than {max} codes read)'**
  String debug_sample_frames_multi(int max);

  /// No description provided for @debug_sample_frames.
  ///
  /// In en, this message translates to:
  /// **'Sample frames (red: no code read)'**
  String get debug_sample_frames;

  /// No description provided for @qr_code.
  ///
  /// In en, this message translates to:
  /// **'QR code'**
  String get qr_code;

  /// No description provided for @filter_qr.
  ///
  /// In en, this message translates to:
  /// **'QR'**
  String get filter_qr;

  /// No description provided for @scanned_at.
  ///
  /// In en, this message translates to:
  /// **'Scanned at {date}'**
  String scanned_at(String date);

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @files_settings.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get files_settings;

  /// No description provided for @show_in_files_app.
  ///
  /// In en, this message translates to:
  /// **'Show in Files app'**
  String get show_in_files_app;

  /// No description provided for @show_in_files_app_hint.
  ///
  /// In en, this message translates to:
  /// **'Lets you open received files from the Files app, and from Finder on a connected Mac.'**
  String get show_in_files_app_hint;
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
      <String>['ar', 'ca', 'en', 'es', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
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
