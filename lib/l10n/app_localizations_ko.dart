// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get blast_title => '블라스트';

  @override
  String get send => '보내기';

  @override
  String get receive => '받기';

  @override
  String get my_files => '받은 파일';

  @override
  String get ok => '확인';

  @override
  String get done => '완료';

  @override
  String get cancel => '취소';

  @override
  String get save => '저장';

  @override
  String get discard => '버리기';

  @override
  String get copy => '복사';

  @override
  String get dismiss => '닫기';

  @override
  String get pick_file_msg => '보낼 파일을 선택하세요';

  @override
  String get keep_scanning_msg => '계속 스캔하세요';

  @override
  String get result => '결과';

  @override
  String get file_name => '파일 이름';

  @override
  String get open => '열기';

  @override
  String get rename => '이름 변경';

  @override
  String get delete => '삭제';

  @override
  String get delete_msg => '이 파일을 삭제하시겠습니까?';

  @override
  String get yes_delete => '네, 삭제합니다';

  @override
  String get save_to_downloads => '다운로드에 저장';

  @override
  String get file_options => '파일 옵션';

  @override
  String get no_files_msg => '파일이 아직 없습니다.';

  @override
  String get saved_to => '저장됨';

  @override
  String get received_in => '받은 날짜';

  @override
  String get large_file => '큰 파일';

  @override
  String get large_file_msg_1 => '선택한 파일이 크기 때문에 최대';

  @override
  String get large_file_msg_2 => '까지 시간이 걸릴 수 있습니다.';

  @override
  String get large_file_msg_3 =>
      'Would you like to send a compresed, lower quality version of this image?';

  @override
  String get minutes => '분';

  @override
  String get image_compression_settings => 'Image settings';

  @override
  String get image_quality => 'Image quality';

  @override
  String get send_large_file => 'Send large file anyway';

  @override
  String get send_compressed_image => 'Send compressed image file';

  @override
  String get to_transfer => '전송';

  @override
  String get generating_codes => '코드 생성 중...';

  @override
  String get send_help_message => '파일을 받을 기기에서 blastQR 앱을 사용해 이 QR 코드를 스캔하세요.';

  @override
  String get scan_help_message =>
      '파일을 받으려면 blastQR 사용하는 다른 기기의 화면에서 QR 코드 시퀀스를 스캔하세요.';

  @override
  String get help => '도움말';

  @override
  String get help_title => 'blastQR 사용 방법';

  @override
  String get help_title_1 => '다른 기기에서 blastQR 앱 받기';

  @override
  String get help_message_1_1 =>
      '파일을 보내거나 받으려면 blastQR 앱을 해당 기기에 다운로드하세요. 두 기기 모두 blastQR 앱이 필요합니다.';

  @override
  String get help_message_1_2 =>
      '이 QR 코드를 스캔하여 다른 기기에 blastQR을 다운로드하세요. 이 코드는 일반적인 QR 코드 스캐너 앱으로도 스캔할 수 있습니다.';

  @override
  String get help_title_2 => '파일 보내기';

  @override
  String get help_message_2 =>
      '앱의 메인 화면에서 보내고 싶은 파일이나 사진을 선택하세요.\n\n선택한 파일이 애니메이션 QR 코드 시퀀스로 변환되며, 이를 blastQR이 설치된 다른 기기에서 스캔할 수 있습니다.';

  @override
  String get help_title_3 => '파일 받기';

  @override
  String get help_message_3 =>
      '다른 기기에서 blastQR 앱을 실행한 후 \'받기\' 탭을 선택하여 애니메이션 QR 코드를 스캔하세요.\n\n받은 파일은 앱의 \'파일\' 탭에 저장됩니다.\n\n팁: 스캔이 갑자기 중지되면 화면을 터치하여 다시 시작하세요.';

  @override
  String get help_title_4 => '추가 정보';

  @override
  String get help_message_4 =>
      '- blastQR 파일 전송은 완전히 오프라인에서 작동합니다.\n\n- 전송된 정보는 암호화되어 있지 않으며, 애니메이션 QR 코드 시퀀스에 접근할 수 있는 누구나 읽을 수 있습니다. 이 앱을 사용하여 민감한 정보를 전송하지 마세요.\n\n- 기술적인 한계로 인해 blastQR 파일 전송 속도는 느리며 (최대 약 40kB/s) 작은 파일 전송을 권장합니다. 또는 사전에 압축하여 전송하세요.\n\n- 더 높은 전송 속도를 원한다면, 전송 기기의 설정 화면에서 \'청크 길이\' 값을 조정할 수 있습니다. 값이 높을수록 속도가 증가할 수 있지만, 모든 기기가 이를 지원하는 것은 아닙니다.\n\n- blastQR을 사용하여 일반적인 QR 코드도 스캔할 수 있습니다.\n\n- blastQR은 오픈 소스 프로젝트입니다. 소스 코드는 다음에서 확인할 수 있습니다:';

  @override
  String get settings => '설정';

  @override
  String get appearance => '모양';

  @override
  String get language => '언어';

  @override
  String get theme => '테마';

  @override
  String get theme_system => '시스템';

  @override
  String get theme_light => '라이트';

  @override
  String get theme_dark => '다크';

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
  String get chunk_length => '청크 길이';

  @override
  String get licenses => '라이선스';

  @override
  String get file_format => 'File format';

  @override
  String get downscaling => 'Downscaling';

  @override
  String get camera_resolution => 'Camera resolution';
}
