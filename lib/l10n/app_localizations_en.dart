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
  String get share => 'Share';

  @override
  String get show_in_file_manager => 'See in file manager';

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
  String get large_file => 'Long transfer';

  @override
  String get large_file_msg_1 => 'This transfer is large and could take up to';

  @override
  String get large_file_msg_2 => 'to transfer.';

  @override
  String large_file_msg_3(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Would you like to send compressed, lower quality versions of these $count images?',
      one:
          'Would you like to send a compressed, lower quality version of this image?',
    );
    return '$_temp0';
  }

  @override
  String get minutes => 'minutes';

  @override
  String get image_compression => 'Image compression';

  @override
  String get image_quality => 'Quality';

  @override
  String get send_large_file => 'Send anyway';

  @override
  String get send_compressed_image => 'Send compressed';

  @override
  String get to_transfer => 'to transfer';

  @override
  String get generating_codes => 'Generating codes...';

  @override
  String get send_help_message =>
      'Scan this QR code using the blastQR app on the device where you want to receive the file';

  @override
  String get scan_help_message =>
      'To receive a file, scan a compatible QR code sequence';

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
      '- blastQR file transfers work completely offline.\n\n- The transferred information is NOT encrypted and can be read by anyone who gains access to the QR code sequence unless using the \'Send password-encrypted\' feature. Avoid using blastQR for transmitting any sensitive information without enabling encryption first and always use strong passwords.\n\n- Due to the nature of the technology, blastQR file transfers are not very fast by default. However, showing multiple codes at once (full-screen button) and raising the \'Playback speed\' in Settings can increase the speed dramatically.\n\n- You can also use blastQR to scan regular QR codes.\n\n- blastQR is an open source project. You can find the source code at:';

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
  String get animations => 'Animated background';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get chunk_length => 'QR code size';

  @override
  String get playback_fps => 'Playback speed';

  @override
  String get licenses => 'Licenses';

  @override
  String get source_code => 'Source code';

  @override
  String get share_app => 'Share blastQR';

  @override
  String get file_format => 'File format';

  @override
  String get downscaling => 'Downscaling';

  @override
  String get camera_resolution => 'Camera preview resolution';

  @override
  String get feedback => 'Feedback';

  @override
  String get haptic_feedback => 'Haptic feedback';

  @override
  String get sound_feedback => 'Sound feedback';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get filter_all => 'All';

  @override
  String get filter_images => 'Images';

  @override
  String get filter_videos => 'Videos';

  @override
  String get filter_audio => 'Audio';

  @override
  String get filter_document => 'Documents';

  @override
  String get filter_book => 'Books';

  @override
  String get filter_other => 'Other';

  @override
  String get older => 'Older';

  @override
  String get select_all => 'Select all';

  @override
  String get selected => 'selected';

  @override
  String get delete_files_msg =>
      'Are you sure you want to delete the selected files?';

  @override
  String files_selected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files selected',
      one: '1 file selected',
    );
    return '$_temp0';
  }

  @override
  String get file_missing => 'File not found';

  @override
  String file_missing_msg(String name) {
    return '$name was moved or deleted.';
  }

  @override
  String get file_too_large => 'File too large';

  @override
  String get file_too_large_msg =>
      'This file exceeds the 4 GB limit and cannot be sent.';

  @override
  String get low_speed_warning =>
      'Low transfer speed. Adjust the position of the devices and keep them still for better performance';

  @override
  String get send_file => 'Send files';

  @override
  String get send_picture => 'Send photos & videos';

  @override
  String get send_file_subtitle => 'Any file type';

  @override
  String get send_picture_subtitle => 'From your photo library';

  @override
  String get drop_files => 'Drop files here';

  @override
  String get drop_files_subtitle => 'or click to choose';

  @override
  String get desktop_receive_unsupported =>
      '* Receiving files is not supported on Windows yet';

  @override
  String get recent => 'Recent';

  @override
  String get clear_recent => 'Clear';

  @override
  String get sending_settings => 'Sending';

  @override
  String get receiving_settings => 'Receiving';

  @override
  String get restore_defaults => 'Restore';

  @override
  String get reset_to_default => 'Reset to default';

  @override
  String get restore_defaults_msg =>
      'Are you sure you want to restore these settings to their default values?';

  @override
  String get qr_codes_section => 'QR Codes';

  @override
  String get chunk_length_hint =>
      '2935 bytes is the recommended value for best performance on most devices';

  @override
  String get playback_fps_hint =>
      '20 FPS is the recommended value for best performance on most devices';

  @override
  String get multi_qr_mode => 'Start in fullscreen';

  @override
  String get multi_qr_mode_subtitle =>
      'Show as many codes as fit on screen for a speed boost';

  @override
  String get images_section => 'Images';

  @override
  String get compress_photos_by_default => 'Compress photos by default';

  @override
  String get compress_photos_by_default_subtitle =>
      'Turn on HD when sending to keep a photo\'s full quality';

  @override
  String get hd_tooltip => 'Enable to send photos in full quality';

  @override
  String get camera_section => 'Camera';

  @override
  String get camera_resolution_hint =>
      'Most devices will perform better with this setting set to \"High\"';

  @override
  String get error => 'Error';

  @override
  String get invalid_downscale_value =>
      'Invalid value (must be larger than 100)';

  @override
  String downscaling_subtitle(String size) {
    return 'Downscaling to ${size}px';
  }

  @override
  String get acoustic_detection => 'Detect completion tone';

  @override
  String get acoustic_detection_subtitle =>
      'Use microphone to detect when a file transfer has finished';

  @override
  String get acoustic_feedback => 'Transfer completion tone';

  @override
  String get transfer_complete => 'Transfer complete!';

  @override
  String get keep_showing_qr => 'Show QR code again';

  @override
  String get mic_permission_title => 'Auto-detect completion';

  @override
  String get mic_permission_message =>
      'blastQR can detect when a transfer has finished by listening for a completion tone through the microphone. Would you like to enable this feature?';

  @override
  String get mic_permission_allow => 'Allow microphone access';

  @override
  String get receive_failed_msg =>
      'The file could not be saved. It may be damaged or larger than 4 GB.';

  @override
  String get file_too_large_for_qr_size_msg =>
      'This file is too large for the current QR code size. Increase the QR code size in Settings › Sending.';

  @override
  String get receiving_generic => 'Receiving file...';

  @override
  String get update_required_title => 'Update needed';

  @override
  String get update_required_msg =>
      'This was sent with a newer version of blastQR. Update the app to receive it.';

  @override
  String get sender_update_required_msg =>
      'This was sent with an older version of blastQR. Ask the sender to update the app.';

  @override
  String get send_encrypted => 'Send password-encrypted';

  @override
  String get receiving_encrypted => 'Receiving encrypted file...';

  @override
  String get enter_password => 'Enter password';

  @override
  String get enter_password_msg =>
      'This file is encrypted. Enter the password from the sender.';

  @override
  String get wrong_password => 'Wrong password. Try again.';

  @override
  String get unlock => 'Unlock';

  @override
  String get received_encrypted => 'Received encrypted';

  @override
  String get show_password => 'Show password';

  @override
  String get password => 'Password';

  @override
  String get new_password => 'New password';

  @override
  String get edit_password => 'Edit password';

  @override
  String password_short_warning(int min) {
    return 'Use at least $min characters.';
  }

  @override
  String get custom_password_title => 'Custom password';

  @override
  String get custom_password_msg =>
      'The file will be encrypted with the following password.';

  @override
  String files_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String sending_files_count(int count) {
    return 'Sending $count files';
  }

  @override
  String get debug => 'Debug';

  @override
  String get camera_zoom => 'Camera zoom';

  @override
  String get camera_zoom_hint =>
      'Zooming in lets the camera read codes from further away, where it can still focus. Helps on phones that can\'t focus up close.';

  @override
  String get crop_camera_preview => 'Crop camera preview';

  @override
  String get crop_camera_preview_hint =>
      'Fills the screen but hides the edges.';

  @override
  String get advanced => 'Advanced';

  @override
  String get allow_video_hdr => 'Allow video HDR';

  @override
  String get allow_video_hdr_hint =>
      'Off by default. HDR can blend two codes into one frame.';

  @override
  String get exposure_time => 'Exposure time';

  @override
  String get exposure_time_hint =>
      'Long exposures blend two codes into one frame when the sender changes code mid-capture. A fixed exposure raises ISO to keep the brightness, so the image gets noisier.';

  @override
  String exposure_auto_capped(String ms) {
    return 'Automatic, max $ms ms (default)';
  }

  @override
  String get exposure_auto => 'Automatic, no limit';

  @override
  String exposure_fixed(String ms) {
    return 'Fixed $ms ms';
  }

  @override
  String get camera_fps => 'Camera FPS';

  @override
  String get camera_fps_hint =>
      'Higher rates give the scanner more chances to read each code. Only the rates this phone supports at the current resolution are listed.';

  @override
  String get fps_default => 'Default';

  @override
  String fps_auto(String fps) {
    return 'Automatic ($fps FPS)';
  }

  @override
  String get debug_share => 'Share';

  @override
  String get debug_clear => 'Clear';

  @override
  String get debug_camera => 'Camera';

  @override
  String get debug_device => 'Device';

  @override
  String get debug_supported_frame_rates => 'Supported FPS';

  @override
  String get debug_save_frames => 'Save sample frames';

  @override
  String get debug_save_frames_hint =>
      'Keeps a few camera frames per transfer, to look at or share.';

  @override
  String get debug_last_transfers => 'Last transfers';

  @override
  String get debug_no_transfers => 'No transfers yet';

  @override
  String get debug_transfers_hint =>
      'The last 5 transfers, kept in memory. Sharing includes every detail. Useful codes are ones read for the first time.';

  @override
  String get debug_unavailable => 'Unavailable';

  @override
  String get debug_status_receiving => 'Receiving';

  @override
  String get debug_status_complete => 'Complete';

  @override
  String get debug_status_stopped => 'Stopped';

  @override
  String get debug_useful_codes => 'Useful codes';

  @override
  String get debug_codes_caught => 'Codes caught';

  @override
  String debug_codes_caught_value(int caught, int shown, String percent) {
    return '$caught of $shown shown ($percent)';
  }

  @override
  String debug_camera_value(String fps, String percent) {
    return '$fps FPS · $percent frames with a code';
  }

  @override
  String get debug_decode => 'Decode';

  @override
  String debug_decode_value(String average, String p95) {
    return '$average avg · $p95 p95';
  }

  @override
  String get debug_exposure => 'Exposure';

  @override
  String debug_frame_codes(int read, int max) {
    return '$read of $max codes read';
  }

  @override
  String get debug_frame_code_read => 'code read';

  @override
  String get debug_frame_no_code => 'no code read';

  @override
  String debug_sample_frames_multi(int max) {
    return 'Sample frames (red: fewer than $max codes read)';
  }

  @override
  String get debug_sample_frames => 'Sample frames (red: no code read)';

  @override
  String get qr_code => 'QR code';

  @override
  String get filter_qr => 'QR';

  @override
  String scanned_at(String date) {
    return 'Scanned at $date';
  }

  @override
  String get copied => 'Copied!';

  @override
  String get files_settings => 'Files';

  @override
  String get show_in_files_app => 'Show in Files app';

  @override
  String get show_in_files_app_hint =>
      'Lets you open received files from the Files app, and from Finder on a connected Mac.';
}
