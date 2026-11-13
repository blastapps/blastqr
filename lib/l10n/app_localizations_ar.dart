// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get blast_title => 'BLAST';

  @override
  String get send => 'إرسال';

  @override
  String get receive => 'استقبال';

  @override
  String get my_files => 'المستلمة';

  @override
  String get ok => 'حسنًا';

  @override
  String get done => 'تم';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get discard => 'تجاهل';

  @override
  String get copy => 'نسخ';

  @override
  String get dismiss => 'إغلاق';

  @override
  String get pick_file_msg => 'اختر ملفًا لإرساله';

  @override
  String get keep_scanning_msg => 'واصل المسح!';

  @override
  String get result => 'النتيجة';

  @override
  String get file_name => 'اسم الملف';

  @override
  String get open => 'فتح';

  @override
  String get share => 'مشاركة';

  @override
  String get show_in_file_manager => 'عرض في مدير الملفات';

  @override
  String get rename => 'إعادة تسمية';

  @override
  String get delete => 'حذف';

  @override
  String get delete_msg => 'هل أنت متأكد من أنك تريد حذف هذا الملف؟';

  @override
  String get yes_delete => 'نعم، احذف';

  @override
  String get save_to_downloads => 'حفظ في التنزيلات';

  @override
  String get save_to_files => 'حفظ في الملفات';

  @override
  String files_saved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم حفظ $count ملف',
      many: 'تم حفظ $count ملفًا',
      few: 'تم حفظ $count ملفات',
      two: 'تم حفظ ملفين',
      one: 'تم حفظ ملف واحد',
      zero: 'لم يُحفظ أي ملف',
    );
    return '$_temp0';
  }

  @override
  String get file_options => 'خيارات الملف';

  @override
  String get no_files_msg => 'لا توجد ملفات بعد.';

  @override
  String get saved_to => 'تم الحفظ في';

  @override
  String get received_in => 'تم الاستلام في';

  @override
  String get large_file => 'نقل طويل';

  @override
  String get large_file_msg_1 => 'هذا النقل كبير وقد يستغرق ما يصل إلى';

  @override
  String get large_file_msg_2 => 'لنقله.';

  @override
  String get minutes => 'دقيقة';

  @override
  String get image_compression => 'ضغط الصور';

  @override
  String get image_quality => 'الجودة';

  @override
  String get send_large_file => 'إرسال على أي حال';

  @override
  String get to_transfer => 'للنقل';

  @override
  String get generating_codes => 'جارٍ إنشاء الرموز...';

  @override
  String get send_help_message =>
      'امسح رمز QR هذا باستخدام تطبيق blastQR على الجهاز الذي تريد استلام الملف عليه';

  @override
  String get scan_help_message =>
      'لاستلام ملف، امسح تسلسلًا متوافقًا من رموز QR';

  @override
  String get help => 'المساعدة';

  @override
  String get help_title => 'كيفية استخدام blastQR';

  @override
  String get help_title_1 => 'احصل على تطبيق blastQR على أجهزة أخرى';

  @override
  String get help_message_1_1 =>
      'نزّل تطبيق blastQR على أي جهاز تريد استلام الملفات أو إرسالها منه. يجب أن يكون تطبيق blastQR مثبتًا على كلا الجهازين.';

  @override
  String get help_message_1_2 =>
      'امسح رمز QR هذا لتنزيل blastQR على جهاز آخر. يمكن مسح هذا الرمز بأي تطبيق عادي لمسح رموز QR. يتوفر blastQR لأنظمة Android وiOS وLinux وmacOS وWindows.';

  @override
  String get help_title_2 => 'إرسال ملف';

  @override
  String get help_message_2 =>
      'من الشاشة الرئيسية للتطبيق، اختر الملف أو الصورة التي تريد إرسالها.\n\nسيتم ترميز الملف في تسلسل من رموز QR يمكنك بعد ذلك مسحه من جهاز آخر مثبت عليه blastQR.';

  @override
  String get help_title_3 => 'استلام ملف';

  @override
  String get help_message_3 =>
      'على جهاز آخر، امسح تسلسل رموز QR باستخدام تطبيق blastQR عبر اختيار علامة التبويب \'استقبال\'.\n\nتُحفظ الملفات التي تستلمها في علامة التبويب \'المستلمة\' داخل التطبيق.\n\nنصيحة: إذا توقفت عملية المسح فجأة، فانقر على الشاشة للاستئناف.';

  @override
  String get help_title_4 => 'معلومات إضافية';

  @override
  String get help_message_4 =>
      '- تعمل عمليات نقل الملفات في blastQR دون اتصال بالإنترنت تمامًا.\n\n- المعلومات المنقولة غير مشفرة ويمكن لأي شخص يصل إلى تسلسل رموز QR قراءتها، ما لم تستخدم ميزة \'إرسال مشفّر بكلمة مرور\'. تجنّب استخدام blastQR لنقل أي معلومات حساسة دون تفعيل التشفير أولًا، واستخدم دائمًا كلمات مرور قوية.\n\n- بسبب طبيعة هذه التقنية، لا تكون عمليات النقل في blastQR سريعة جدًا في الإعدادات الافتراضية. لكن عرض عدة رموز في الوقت نفسه (زر ملء الشاشة) ورفع \'سرعة التشغيل\' في الإعدادات يمكن أن يزيد السرعة بشكل كبير.\n\n- يمكنك أيضًا استخدام blastQR لمسح رموز QR العادية.\n\n- blastQR مشروع مفتوح المصدر. يمكنك العثور على الشيفرة المصدرية على:';

  @override
  String get settings => 'الإعدادات';

  @override
  String get appearance => 'المظهر';

  @override
  String get language => 'اللغة';

  @override
  String get theme => 'السمة';

  @override
  String get theme_system => 'النظام';

  @override
  String get theme_light => 'فاتح';

  @override
  String get theme_dark => 'داكن';

  @override
  String get pure_black => 'استخدام اللون الأسود الخالص';

  @override
  String get accent_color => 'لون التمييز';

  @override
  String get animations => 'خلفية متحركة';

  @override
  String get enabled => 'مفعّل';

  @override
  String get disabled => 'معطّل';

  @override
  String get chunk_length => 'حجم رمز QR';

  @override
  String get playback_fps => 'سرعة التشغيل';

  @override
  String get licenses => 'التراخيص';

  @override
  String get source_code => 'الشيفرة المصدرية';

  @override
  String get share_app => 'مشاركة blastQR';

  @override
  String get file_format => 'صيغة الملف';

  @override
  String get downscaling => 'تصغير الأبعاد';

  @override
  String get camera_resolution => 'دقة معاينة الكاميرا';

  @override
  String get feedback => 'الاستجابة';

  @override
  String get haptic_feedback => 'الاستجابة اللمسية';

  @override
  String get sound_feedback => 'الاستجابة الصوتية';

  @override
  String get today => 'اليوم';

  @override
  String get yesterday => 'أمس';

  @override
  String get filter_all => 'الكل';

  @override
  String get filter_images => 'الصور';

  @override
  String get filter_videos => 'الفيديوهات';

  @override
  String get filter_audio => 'الصوت';

  @override
  String get filter_document => 'المستندات';

  @override
  String get filter_book => 'الكتب';

  @override
  String get filter_other => 'أخرى';

  @override
  String get older => 'أقدم';

  @override
  String get select_all => 'تحديد الكل';

  @override
  String get selected => 'محدد';

  @override
  String get delete_files_msg =>
      'هل أنت متأكد من أنك تريد حذف الملفات المحددة؟';

  @override
  String files_selected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم تحديد $count ملف',
      many: 'تم تحديد $count ملفًا',
      few: 'تم تحديد $count ملفات',
      two: 'تم تحديد ملفين',
      one: 'تم تحديد ملف واحد',
      zero: 'لم يُحدد أي ملف',
    );
    return '$_temp0';
  }

  @override
  String get file_missing => 'الملف غير موجود';

  @override
  String file_missing_msg(String name) {
    return 'تم نقل $name أو حذفه.';
  }

  @override
  String get file_too_large => 'الملف كبير جدًا';

  @override
  String get file_too_large_msg =>
      'يتجاوز هذا الملف الحد الأقصى البالغ 4 غيغابايت ولا يمكن إرساله.';

  @override
  String get low_speed_warning =>
      'سرعة النقل منخفضة. عدّل وضع الجهازين وأبقهما ثابتين للحصول على أداء أفضل';

  @override
  String get send_file => 'إرسال ملفات';

  @override
  String get send_picture => 'إرسال صور وفيديوهات';

  @override
  String get send_file_subtitle => 'أي نوع من الملفات';

  @override
  String get send_picture_subtitle => 'من مكتبة الصور';

  @override
  String get drop_files => 'أفلت الملفات هنا';

  @override
  String get drop_files_subtitle => 'أو انقر للاختيار';

  @override
  String get desktop_receive_unsupported =>
      '* استلام الملفات غير مدعوم على Windows بعد';

  @override
  String get recent => 'الأخيرة';

  @override
  String get clear_recent => 'مسح';

  @override
  String get sending_settings => 'الإرسال';

  @override
  String get receiving_settings => 'الاستقبال';

  @override
  String get restore_defaults => 'استعادة';

  @override
  String get reset_to_default => 'إعادة التعيين إلى الافتراضي';

  @override
  String get restore_defaults_msg =>
      'هل أنت متأكد من أنك تريد استعادة القيم الافتراضية لهذه الإعدادات؟';

  @override
  String get qr_codes_section => 'رموز QR';

  @override
  String get chunk_length_hint =>
      '2935 بايت هي القيمة الموصى بها لأفضل أداء على معظم الأجهزة';

  @override
  String get playback_fps_hint =>
      '20 إطارًا في الثانية هي القيمة الموصى بها لأفضل أداء على معظم الأجهزة';

  @override
  String get multi_qr_mode => 'البدء في وضع ملء الشاشة';

  @override
  String get multi_qr_mode_subtitle =>
      'عرض أكبر عدد ممكن من الرموز على الشاشة لزيادة السرعة';

  @override
  String get compress_media_by_default => 'ضغط الوسائط افتراضيًا';

  @override
  String get compress_media_by_default_subtitle =>
      'ملفات أصغر تُرسل أسرع، بجودة أقل';

  @override
  String get hd_tooltip => 'فعّله لإرسال الصور ومقاطع الفيديو بالجودة الكاملة';

  @override
  String get camera_section => 'الكاميرا';

  @override
  String get camera_resolution_hint =>
      'ستعمل معظم الأجهزة بشكل أفضل عند ضبط هذا الإعداد على \"عالية\"';

  @override
  String get error => 'خطأ';

  @override
  String get invalid_downscale_value =>
      'قيمة غير صالحة (يجب أن تكون أكبر من 100)';

  @override
  String downscaling_subtitle(String size) {
    return 'التصغير إلى $size بكسل';
  }

  @override
  String get acoustic_detection => 'اكتشاف نغمة الاكتمال';

  @override
  String get acoustic_detection_subtitle =>
      'استخدام الميكروفون لاكتشاف انتهاء نقل الملف';

  @override
  String get acoustic_feedback => 'نغمة اكتمال النقل';

  @override
  String get transfer_complete => 'اكتمل النقل!';

  @override
  String get keep_showing_qr => 'عرض رمز QR مرة أخرى';

  @override
  String get mic_permission_title => 'الاكتشاف التلقائي للاكتمال';

  @override
  String get mic_permission_message =>
      'يمكن لتطبيق blastQR اكتشاف انتهاء النقل عبر الاستماع إلى نغمة الاكتمال من خلال الميكروفون. هل تريد تفعيل هذه الميزة؟';

  @override
  String get mic_permission_allow => 'السماح بالوصول إلى الميكروفون';

  @override
  String get receive_failed_msg =>
      'تعذّر حفظ الملف. قد يكون تالفًا أو أكبر من 4 غيغابايت.';

  @override
  String get file_too_large_for_qr_size_msg =>
      'هذا الملف كبير جدًا بالنسبة لحجم رمز QR الحالي. زِد حجم رمز QR من الإعدادات › الإرسال.';

  @override
  String get receiving_generic => 'جارٍ استلام الملف...';

  @override
  String get update_required_title => 'التحديث مطلوب';

  @override
  String get update_required_msg =>
      'تم إرسال هذا بإصدار أحدث من blastQR. حدّث التطبيق لاستلامه.';

  @override
  String get sender_update_required_msg =>
      'تم إرسال هذا بإصدار أقدم من blastQR. اطلب من المرسل تحديث التطبيق.';

  @override
  String get send_encrypted => 'إرسال مشفّر بكلمة مرور';

  @override
  String get receiving_encrypted => 'جارٍ استلام ملف مشفّر...';

  @override
  String get enter_password => 'أدخل كلمة المرور';

  @override
  String get enter_password_msg =>
      'هذا الملف مشفّر. أدخل كلمة المرور التي زوّدك بها المرسل.';

  @override
  String get wrong_password => 'كلمة مرور خاطئة. حاول مرة أخرى.';

  @override
  String get unlock => 'فتح القفل';

  @override
  String get received_encrypted => 'تم استلامه مشفّرًا';

  @override
  String get show_password => 'إظهار كلمة المرور';

  @override
  String get password => 'كلمة المرور';

  @override
  String get new_password => 'كلمة مرور جديدة';

  @override
  String get edit_password => 'تعديل كلمة المرور';

  @override
  String password_short_warning(int min) {
    return 'استخدم $min أحرف على الأقل.';
  }

  @override
  String get custom_password_title => 'كلمة مرور مخصصة';

  @override
  String get custom_password_msg => 'سيتم تشفير الملف بكلمة المرور التالية.';

  @override
  String files_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ملف',
      many: '$count ملفًا',
      few: '$count ملفات',
      two: 'ملفان',
      one: 'ملف واحد',
      zero: 'لا ملفات',
    );
    return '$_temp0';
  }

  @override
  String sending_files_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'جارٍ إرسال $count ملف',
      many: 'جارٍ إرسال $count ملفًا',
      few: 'جارٍ إرسال $count ملفات',
      two: 'جارٍ إرسال ملفين',
    );
    return '$_temp0';
  }

  @override
  String get debug => 'تصحيح الأخطاء';

  @override
  String get camera_zoom => 'تكبير الكاميرا';

  @override
  String get camera_zoom_hint =>
      'يتيح التكبير للكاميرا قراءة الرموز من مسافة أبعد يمكنها التركيز عليها. يفيد في الهواتف التي لا تستطيع التركيز عن قرب.';

  @override
  String get crop_camera_preview => 'قص معاينة الكاميرا';

  @override
  String get crop_camera_preview_hint => 'تملأ الشاشة لكنها تخفي الأطراف.';

  @override
  String get advanced => 'متقدم';

  @override
  String get allow_video_hdr => 'السماح بفيديو HDR';

  @override
  String get allow_video_hdr_hint =>
      'معطّل افتراضيًا. قد يدمج HDR رمزين في إطار واحد.';

  @override
  String get exposure_time => 'مدة التعريض';

  @override
  String get exposure_time_hint =>
      'يؤدي التعريض الطويل إلى دمج رمزين في إطار واحد عندما يغيّر المرسل الرمز أثناء الالتقاط. يرفع التعريض الثابت قيمة ISO للحفاظ على السطوع، فتصبح الصورة أكثر تشويشًا.';

  @override
  String exposure_auto_capped(String ms) {
    return 'تلقائي، بحد أقصى $ms ملّي ثانية (افتراضي)';
  }

  @override
  String get exposure_auto => 'تلقائي، بلا حد';

  @override
  String exposure_fixed(String ms) {
    return 'ثابت $ms ملّي ثانية';
  }

  @override
  String get camera_fps => 'معدل إطارات الكاميرا';

  @override
  String get camera_fps_hint =>
      'تمنح المعدلات الأعلى الماسح فرصًا أكثر لقراءة كل رمز. تُعرض فقط المعدلات التي يدعمها هذا الهاتف بالدقة الحالية.';

  @override
  String get fps_default => 'افتراضي';

  @override
  String fps_auto(String fps) {
    return 'تلقائي ($fps إطار/ث)';
  }

  @override
  String get debug_share => 'مشاركة';

  @override
  String get debug_clear => 'مسح';

  @override
  String get debug_camera => 'الكاميرا';

  @override
  String get debug_device => 'الجهاز';

  @override
  String get debug_supported_frame_rates => 'معدلات الإطارات المدعومة';

  @override
  String get debug_save_frames => 'حفظ إطارات نموذجية';

  @override
  String get debug_save_frames_hint =>
      'يحتفظ ببضعة إطارات من الكاميرا لكل عملية نقل، لعرضها أو مشاركتها.';

  @override
  String get debug_last_transfers => 'آخر عمليات النقل';

  @override
  String get debug_no_transfers => 'لا توجد عمليات نقل بعد';

  @override
  String get debug_transfers_hint =>
      'آخر 5 عمليات نقل، محفوظة في الذاكرة. تتضمن المشاركة كل التفاصيل. الرموز المفيدة هي التي تُقرأ لأول مرة.';

  @override
  String get debug_unavailable => 'غير متاح';

  @override
  String get debug_status_receiving => 'جارٍ الاستلام';

  @override
  String get debug_status_complete => 'مكتمل';

  @override
  String get debug_status_stopped => 'متوقف';

  @override
  String get debug_useful_codes => 'الرموز المفيدة';

  @override
  String get debug_codes_caught => 'الرموز الملتقطة';

  @override
  String debug_codes_caught_value(int caught, int shown, String percent) {
    return '$caught من $shown معروضة ($percent)';
  }

  @override
  String debug_camera_value(String fps, String percent) {
    return '$fps إطار/ث · $percent من الإطارات تحتوي على رمز';
  }

  @override
  String get debug_decode => 'فك الترميز';

  @override
  String debug_decode_value(String average, String p95) {
    return '$average متوسط · $p95 p95';
  }

  @override
  String get debug_exposure => 'التعريض';

  @override
  String debug_frame_codes(int read, int max) {
    return 'تمت قراءة $read من $max رموز';
  }

  @override
  String get debug_frame_code_read => 'تمت قراءة الرمز';

  @override
  String get debug_frame_no_code => 'لم تتم قراءة أي رمز';

  @override
  String debug_sample_frames_multi(int max) {
    return 'إطارات نموذجية (الأحمر: قراءة أقل من $max رموز)';
  }

  @override
  String get debug_sample_frames =>
      'إطارات نموذجية (الأحمر: لم تتم قراءة أي رمز)';

  @override
  String get qr_code => 'رمز QR';

  @override
  String get filter_qr => 'QR';

  @override
  String scanned_at(String date) {
    return 'تم المسح في $date';
  }

  @override
  String get copied => 'تم النسخ!';

  @override
  String get files_settings => 'الملفات';

  @override
  String get show_in_files_app => 'العرض في تطبيق الملفات';

  @override
  String get show_in_files_app_hint =>
      'يتيح لك فتح الملفات المستلمة من تطبيق الملفات، ومن Finder على جهاز Mac متصل.';

  @override
  String get qr_tooltip_fps => 'تغيير سرعة التشغيل';

  @override
  String get qr_tooltip_fullscreen => 'ملء الشاشة';

  @override
  String get qr_tooltip_tone_on => 'إيقاف اكتشاف نغمة الاكتمال';

  @override
  String get qr_tooltip_tone_off => 'اكتشاف نغمة الاكتمال عبر الميكروفون';

  @override
  String get camera_permission_msg =>
      'لا يمكن لتطبيق blastQR الوصول إلى الكاميرا. اسمح بالوصول إلى الكاميرا لاستلام الملفات.';

  @override
  String get enable_camera => 'تفعيل الكاميرا';

  @override
  String compressing_videos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'جارٍ ضغط $count من مقاطع الفيديو',
      one: 'جارٍ ضغط الفيديو',
    );
    return '$_temp0';
  }

  @override
  String time_left_seconds(int seconds) {
    return 'يتبقى حوالي $seconds ثانية';
  }

  @override
  String time_left_minutes(int minutes) {
    return 'يتبقى حوالي $minutes دقيقة';
  }

  @override
  String get preparing_transfer => 'جارٍ تجهيز النقل...';

  @override
  String get send_files_title => 'إرسال الملفات';

  @override
  String get photos_and_videos_section => 'الصور ومقاطع الفيديو';

  @override
  String get video_quality => 'جودة الفيديو';

  @override
  String get video_quality_hint =>
      'تُضغط مقاطع الفيديو إلى هذه الجودة عند إيقاف HD';

  @override
  String get video_quality_original => 'الأصلية';

  @override
  String get video_quality_low => 'منخفضة (540p)';

  @override
  String get video_quality_lowest => 'الأدنى (360p)';

  @override
  String get video_quality_potato => 'بطاطس (240p)';

  @override
  String send_time_seconds(int seconds) {
    return 'حوالي $seconds ثانية للإرسال';
  }

  @override
  String send_time_minutes(int minutes) {
    return 'حوالي $minutes دقيقة للإرسال';
  }

  @override
  String get stop_sending => 'إيقاف الإرسال؟';

  @override
  String get stop_sending_msg => 'لم يستلم المستقبِل الملف كاملًا بعد.';

  @override
  String get stop => 'إيقاف';

  @override
  String get keep_sending => 'متابعة الإرسال';
}
