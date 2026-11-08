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
  String get share => '공유';

  @override
  String get show_in_file_manager => '파일 관리자에서 보기';

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
  String get large_file => '긴 전송';

  @override
  String get large_file_msg_1 => '이 전송은 크기 때문에 최대';

  @override
  String get large_file_msg_2 => '까지 시간이 걸릴 수 있습니다.';

  @override
  String large_file_msg_3(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '이 이미지 $count개의 압축된 저화질 버전을 전송하시겠습니까?',
      one: '이 이미지의 압축된 저화질 버전을 전송하시겠습니까?',
    );
    return '$_temp0';
  }

  @override
  String get minutes => '분';

  @override
  String get image_compression => '이미지 압축';

  @override
  String get image_quality => '화질';

  @override
  String get send_large_file => '그래도 보내기';

  @override
  String get send_compressed_image => '압축해서 보내기';

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
      '- blastQR 파일 전송은 완전히 오프라인에서 작동합니다.\n\n- 전송된 정보는 \'비밀번호로 암호화해서 보내기\' 기능을 사용하지 않는 한 암호화되지 않으며, QR 코드 시퀀스에 접근할 수 있는 누구나 읽을 수 있습니다. 먼저 암호화를 활성화하지 않은 상태에서는 민감한 정보를 전송하지 마시고, 항상 강력한 비밀번호를 사용하세요.\n\n- 기술적인 특성상 blastQR 파일 전송은 기본 설정에서는 그리 빠르지 않습니다. 하지만 여러 코드를 동시에 표시하고(전체 화면 버튼) 설정에서 \'재생 속도\'를 높이면 속도를 크게 높일 수 있습니다.\n\n- blastQR을 사용하여 일반적인 QR 코드도 스캔할 수 있습니다.\n\n- blastQR은 오픈 소스 프로젝트입니다. 소스 코드는 다음에서 확인할 수 있습니다:';

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
  String get pure_black => '순수 검정색 사용';

  @override
  String get accent_color => '강조 색상';

  @override
  String get animations => '애니메이션 배경';

  @override
  String get enabled => '활성화';

  @override
  String get disabled => '비활성화';

  @override
  String get chunk_length => 'QR 코드 크기';

  @override
  String get playback_fps => '재생 속도';

  @override
  String get licenses => '라이선스';

  @override
  String get source_code => '소스 코드';

  @override
  String get share_app => 'blastQR 공유하기';

  @override
  String get file_format => '파일 형식';

  @override
  String get downscaling => '다운스케일링';

  @override
  String get camera_resolution => '카메라 미리보기 해상도';

  @override
  String get feedback => '피드백';

  @override
  String get haptic_feedback => '햅틱 피드백';

  @override
  String get sound_feedback => '소리 피드백';

  @override
  String get today => '오늘';

  @override
  String get yesterday => '어제';

  @override
  String get filter_all => '전체';

  @override
  String get filter_images => '이미지';

  @override
  String get filter_videos => '동영상';

  @override
  String get filter_audio => '오디오';

  @override
  String get filter_document => '문서';

  @override
  String get filter_book => '책';

  @override
  String get filter_other => '기타';

  @override
  String get older => '이전 파일';

  @override
  String get select_all => '전체 선택';

  @override
  String get selected => '선택됨';

  @override
  String get delete_files_msg => '선택한 파일을 삭제하시겠습니까?';

  @override
  String files_selected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '파일 $count개 선택됨',
    );
    return '$_temp0';
  }

  @override
  String get file_missing => '파일을 찾을 수 없음';

  @override
  String file_missing_msg(String name) {
    return '$name 파일이 이동되었거나 삭제되었습니다.';
  }

  @override
  String get file_too_large => '파일이 너무 큽니다';

  @override
  String get file_too_large_msg => '이 파일은 4GB 제한을 초과하여 전송할 수 없습니다.';

  @override
  String get low_speed_warning => '전송 속도가 느립니다. 기기 위치를 조정하고 움직이지 마세요';

  @override
  String get send_file => '파일 보내기';

  @override
  String get send_picture => '사진 및 동영상 보내기';

  @override
  String get send_file_subtitle => '모든 파일 형식';

  @override
  String get send_picture_subtitle => '사진 보관함에서';

  @override
  String get drop_files => '여기에 파일을 놓으세요';

  @override
  String get drop_files_subtitle => '또는 클릭하여 선택하세요';

  @override
  String get desktop_receive_unsupported => '* Windows에서는 아직 파일 수신이 지원되지 않습니다';

  @override
  String get recent => '최근';

  @override
  String get clear_recent => '지우기';

  @override
  String get sending_settings => '전송 설정';

  @override
  String get receiving_settings => '수신 설정';

  @override
  String get restore_defaults => '기본값 복원';

  @override
  String get reset_to_default => '기본값으로 재설정';

  @override
  String get restore_defaults_msg => '이 설정을 기본값으로 복원하시겠습니까?';

  @override
  String get qr_codes_section => 'QR 코드';

  @override
  String get chunk_length_hint => '2935바이트는 대부분의 기기에서 최상의 성능을 위한 권장 값입니다';

  @override
  String get playback_fps_hint => '20 FPS는 대부분의 기기에서 최상의 성능을 위한 권장 값입니다';

  @override
  String get multi_qr_mode => '전체 화면으로 시작';

  @override
  String get multi_qr_mode_subtitle => '화면에 들어가는 만큼 코드를 표시해 속도를 높입니다';

  @override
  String get images_section => '이미지';

  @override
  String get compress_photos_by_default => '기본으로 사진 압축';

  @override
  String get compress_photos_by_default_subtitle => '보낼 때 HD를 켜면 원본 화질로 보냅니다';

  @override
  String get hd_tooltip => '켜면 사진을 원본 화질로 보냅니다';

  @override
  String get camera_section => '카메라';

  @override
  String get camera_resolution_hint =>
      '대부분의 기기는 이 설정을 \"High\"으로 설정하면 더 잘 작동합니다';

  @override
  String get error => '오류';

  @override
  String get invalid_downscale_value => '잘못된 값 (100보다 커야 합니다)';

  @override
  String downscaling_subtitle(String size) {
    return '${size}px로 축소';
  }

  @override
  String get acoustic_detection => '완료 알림음 감지';

  @override
  String get acoustic_detection_subtitle => '마이크를 사용하여 파일 전송이 끝났는지 감지합니다';

  @override
  String get acoustic_feedback => '전송 완료 알림음';

  @override
  String get transfer_complete => '전송 완료!';

  @override
  String get keep_showing_qr => 'QR 코드 다시 표시';

  @override
  String get mic_permission_title => '자동 전송 감지';

  @override
  String get mic_permission_message =>
      'blastQR는 마이크를 통해 완료 신호음을 감지하여 전송이 완료되었는지 자동으로 알 수 있습니다. 이 기능을 활성화하시겠습니까?';

  @override
  String get mic_permission_allow => '마이크 접근 허용';

  @override
  String get receive_failed_msg =>
      '파일을 저장할 수 없습니다. 파일이 손상되었거나 4GB를 초과할 수 있습니다.';

  @override
  String get file_too_large_for_qr_size_msg =>
      '현재 QR 코드 크기로는 이 파일을 보낼 수 없습니다. 설정 › 전송 설정에서 QR 코드 크기를 늘려 주세요.';

  @override
  String get receiving_generic => '파일 수신 중...';

  @override
  String get update_required_title => '업데이트 필요';

  @override
  String get update_required_msg =>
      '최신 버전의 blastQR로 보낸 파일입니다. 받으려면 앱을 업데이트하세요.';

  @override
  String get sender_update_required_msg =>
      '이전 버전의 blastQR로 보낸 파일입니다. 보낸 사람에게 앱을 업데이트하도록 요청하세요.';

  @override
  String get send_encrypted => '비밀번호로 암호화해서 보내기';

  @override
  String get receiving_encrypted => '암호화된 파일 수신 중...';

  @override
  String get enter_password => '비밀번호 입력';

  @override
  String get enter_password_msg => '이 파일은 암호화되어 있습니다. 보낸 사람의 비밀번호를 입력하세요.';

  @override
  String get wrong_password => '비밀번호가 틀렸습니다. 다시 시도하세요.';

  @override
  String get unlock => '잠금 해제';

  @override
  String get received_encrypted => '암호화되어 수신됨';

  @override
  String get show_password => '비밀번호 보기';

  @override
  String get password => '비밀번호';

  @override
  String get new_password => '새 비밀번호';

  @override
  String get edit_password => '비밀번호 편집';

  @override
  String password_short_warning(int min) {
    return '$min자 이상 입력하세요.';
  }

  @override
  String get custom_password_title => '사용자 지정 비밀번호';

  @override
  String get custom_password_msg => '파일이 다음 비밀번호로 암호화됩니다.';

  @override
  String files_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '파일 $count개',
    );
    return '$_temp0';
  }

  @override
  String sending_files_count(int count) {
    return '파일 $count개 보내는 중';
  }

  @override
  String get debug => '디버그';

  @override
  String get camera_zoom => '카메라 확대';

  @override
  String get camera_zoom_hint =>
      '확대하면 카메라가 초점을 맞출 수 있는 더 먼 거리에서도 코드를 읽을 수 있습니다. 가까이에서 초점을 맞추지 못하는 휴대폰에 도움이 됩니다.';

  @override
  String get crop_camera_preview => '카메라 미리보기 자르기';

  @override
  String get crop_camera_preview_hint => '화면을 채우지만 가장자리가 가려집니다.';

  @override
  String get advanced => '고급';

  @override
  String get allow_video_hdr => '비디오 HDR 허용';

  @override
  String get allow_video_hdr_hint => '기본값은 꺼짐입니다. HDR은 두 코드를 한 프레임에 섞을 수 있습니다.';

  @override
  String get exposure_time => '노출 시간';

  @override
  String get exposure_time_hint =>
      '노출이 길면 촬영 중에 보내는 기기의 코드가 바뀔 때 두 코드가 한 프레임에 섞입니다. 노출을 고정하면 밝기를 유지하려고 ISO가 올라가서 이미지에 노이즈가 더 생깁니다.';

  @override
  String exposure_auto_capped(String ms) {
    return '자동, 최대 ${ms}ms (기본값)';
  }

  @override
  String get exposure_auto => '자동, 제한 없음';

  @override
  String exposure_fixed(String ms) {
    return '고정 ${ms}ms';
  }

  @override
  String get camera_fps => '카메라 FPS';

  @override
  String get camera_fps_hint =>
      '속도가 높을수록 스캐너가 각 코드를 읽을 기회가 많아집니다. 현재 해상도에서 이 휴대폰이 지원하는 속도만 표시됩니다.';

  @override
  String get fps_default => '기본값';

  @override
  String fps_auto(String fps) {
    return '자동 ($fps FPS)';
  }

  @override
  String get debug_share => '공유';

  @override
  String get debug_clear => '지우기';

  @override
  String get debug_camera => '카메라';

  @override
  String get debug_device => '기기';

  @override
  String get debug_supported_frame_rates => '지원되는 FPS';

  @override
  String get debug_save_frames => '샘플 프레임 저장';

  @override
  String get debug_save_frames_hint =>
      '전송마다 카메라 프레임 몇 장을 저장해 확인하거나 공유할 수 있습니다.';

  @override
  String get debug_last_transfers => '최근 전송';

  @override
  String get debug_no_transfers => '아직 전송 기록이 없습니다';

  @override
  String get debug_transfers_hint =>
      '최근 5개의 전송이 메모리에 보관됩니다. 공유하면 모든 세부 정보가 포함됩니다. 유용한 코드는 처음 읽힌 코드입니다.';

  @override
  String get debug_unavailable => '사용할 수 없음';

  @override
  String get debug_status_receiving => '수신 중';

  @override
  String get debug_status_complete => '완료';

  @override
  String get debug_status_stopped => '중지됨';

  @override
  String get debug_useful_codes => '유용한 코드';

  @override
  String get debug_codes_caught => '포착한 코드';

  @override
  String debug_codes_caught_value(int caught, int shown, String percent) {
    return '표시된 $shown개 중 $caught개 ($percent)';
  }

  @override
  String debug_camera_value(String fps, String percent) {
    return '$fps FPS · 프레임의 $percent에서 코드 인식';
  }

  @override
  String get debug_decode => '디코딩';

  @override
  String debug_decode_value(String average, String p95) {
    return '평균 $average · p95 $p95';
  }

  @override
  String get debug_exposure => '노출';

  @override
  String debug_frame_codes(int read, int max) {
    return '$max개 중 $read개 코드 읽음';
  }

  @override
  String get debug_frame_code_read => '코드 읽음';

  @override
  String get debug_frame_no_code => '읽은 코드 없음';

  @override
  String debug_sample_frames_multi(int max) {
    return '샘플 프레임 (빨간색: 읽은 코드 $max개 미만)';
  }

  @override
  String get debug_sample_frames => '샘플 프레임 (빨간색: 읽은 코드 없음)';

  @override
  String get qr_code => 'QR 코드';

  @override
  String get filter_qr => 'QR';

  @override
  String scanned_at(String date) {
    return '$date에 스캔함';
  }

  @override
  String get copied => '복사됨';

  @override
  String get files_settings => '파일';

  @override
  String get show_in_files_app => '파일 앱에 표시';

  @override
  String get show_in_files_app_hint =>
      '받은 파일을 파일 앱과 연결된 Mac의 Finder에서 열 수 있습니다.';
}
