// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get blast_title => 'BLAST';

  @override
  String get send => 'Send';

  @override
  String get receive => 'Receive';

  @override
  String get my_files => 'Received';

  @override
  String get ok => 'OK';

  @override
  String get done => 'Done';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get discard => 'Discard';

  @override
  String get copy => 'Copy';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get pick_file_msg => 'Pick a file to send';

  @override
  String get keep_scanning_msg => 'Keep scanning!';

  @override
  String get result => 'Result';

  @override
  String get file_name => 'File name';

  @override
  String get open => 'Open';

  @override
  String get rename => 'Rename';

  @override
  String get delete => 'Delete';

  @override
  String get delete_msg => 'Are you sure you want to delete this file?';

  @override
  String get yes_delete => 'Yes, delete';

  @override
  String get save_to_downloads => 'Save to Downloads';

  @override
  String get file_options => 'File options';

  @override
  String get no_files_msg => 'No files yet.';

  @override
  String get saved_to => 'Saved to';

  @override
  String get received_in => 'Received in';

  @override
  String get large_file => 'Large file';

  @override
  String get large_file_msg_1 =>
      'The file you selected is large and could take up to';

  @override
  String get large_file_msg_2 => 'to transfer.';

  @override
  String get large_file_msg_3 =>
      'Would you like to send a compresed, lower quality version of this image?';

  @override
  String get minutes => 'minutes';

  @override
  String get image_compression_settings => 'Picture compression settings';

  @override
  String get image_quality => 'Image quality';

  @override
  String get send_large_file => 'Send large file anyway';

  @override
  String get send_compressed_image => 'Send compressed image file';

  @override
  String get to_transfer => 'to transfer';

  @override
  String get generating_codes => 'Generating codes...';

  @override
  String get send_help_message =>
      'Scan this QR code using the blastQR app on the device where you want to receive the file.';

  @override
  String get scan_help_message =>
      'To receive a file, scan a QR code sequence from the screen of another device that uses blastQR.';

  @override
  String get help => 'Help';

  @override
  String get help_title => 'How to use blastQR';

  @override
  String get help_title_1 => 'Get the blastQR app on other devices';

  @override
  String get help_message_1_1 =>
      'Download the blastQR app on any device where you want to receive or send files. Both devices need to have the blastQR app.';

  @override
  String get help_message_1_2 =>
      'Scan this QR code to download blastQR on another device. This particular code can be scanned using any regular QR code scanning app. blastQR is available for Android, iOS, Linux, macOS and Windows.';

  @override
  String get help_title_2 => 'Sending a file';

  @override
  String get help_message_2 =>
      'From the app\'s main screen, select the file or picture that you want to send.\n\nThe file will be encoded into a sequence of QR codes that you can then scan from another device that has blastQR installed.';

  @override
  String get help_title_3 => 'Receiving a file';

  @override
  String get help_message_3 =>
      'On another device, scan the QR code sequence using the blastQR app by selecting the \'Receive\' tab.\n\nThe files you receive are stored in the \'Received\' tab within the app.\n\nTIP: If the scanning process suddenly stops tap on the screen to resume.';

  @override
  String get help_title_4 => 'Additional information';

  @override
  String get help_message_4 =>
      '- blastQR file transfers work completely offline.\n\n- The transferred information is NOT encrypted and can be read by anyone who gains access to the QR code sequence. Avoid using blastQR for transmitting any sensitive information.\n\n- Due to the nature of the technology blastQR file transfers are slow (peaking at around 40kB/s). I recommend transferring small files or compressing them in advance.\n\n- For higher speeds play with the \'Chunk length\' setting in the Settings screen of the sending device. A higher value can result in higher speeds.\n\n- You can also use blastQR to scan regular QR codes.\n\n- blastQR is an open source project. You can find the source code at:';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get theme_system => 'System';

  @override
  String get theme_light => 'Light';

  @override
  String get theme_dark => 'Dark';

  @override
  String get pure_black => 'Use pure black color';

  @override
  String get accent_color => 'Accent color';

  @override
  String get animations => 'Animations';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get behaviour => 'Behaviour';

  @override
  String get chunk_length => 'Chunk length';

  @override
  String get licenses => 'Licenses';

  @override
  String get file_format => 'File format';

  @override
  String get downscaling => 'Downscaling';
}
