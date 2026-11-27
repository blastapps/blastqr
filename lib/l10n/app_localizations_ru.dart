// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get blast_title => 'BLAST';

  @override
  String get send => 'Отправить';

  @override
  String get receive => 'Получить';

  @override
  String get my_files => 'Пол. файлы';

  @override
  String get ok => 'OK';

  @override
  String get done => 'Готово';

  @override
  String get cancel => 'Отменить';

  @override
  String get save => 'Сохранить';

  @override
  String get discard => 'Удалить';

  @override
  String get copy => 'Копировать';

  @override
  String get dismiss => 'Отклонить';

  @override
  String get pick_file_msg => 'Выберите файл для отправки';

  @override
  String get keep_scanning_msg => 'Продолжайте сканировать!';

  @override
  String get result => 'Результат';

  @override
  String get file_name => 'Имя файла';

  @override
  String get open => 'Открыть';

  @override
  String get share => 'Поделиться';

  @override
  String get show_in_file_manager => 'Посмотреть в файловом менеджере';

  @override
  String get rename => 'Переименовать';

  @override
  String get delete => 'Удалить';

  @override
  String get delete_msg => 'Вы уверены, что хотите удалить этот файл?';

  @override
  String get yes_delete => 'Да, удалить';

  @override
  String get save_to_downloads => 'Сохранить в скачанные';

  @override
  String get save_to_files => 'Сохранить в файлы';

  @override
  String files_saved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count файлов сохранены',
      one: '1 файл сохранен',
    );
    return '$_temp0';
  }

  @override
  String get file_options => 'Опции файлов';

  @override
  String get no_files_msg => 'Нет файлов.';

  @override
  String saved_to(String path) {
    return 'Сохранено в $path';
  }

  @override
  String received_in(String seconds, String speed) {
    return 'Полученно на протяжении ${seconds}s (${speed}kB/s)';
  }

  @override
  String get large_file => 'Длительная передача';

  @override
  String large_file_msg(String duration) {
    return 'This transfer is large and could take up to $duration to transfer.';
  }

  @override
  String large_file_duration(int minutes) {
    return '$minutes минут';
  }

  @override
  String get image_compression => 'Сжатие изображения';

  @override
  String get image_quality => 'Качество';

  @override
  String get send_large_file => 'Отправить';

  @override
  String get low_memory => 'Слишком большой для устройства';

  @override
  String get low_memory_msg =>
      'Файл слишком большой для памяти данного устройства. Вероятно, приложение закроется до завершения передачи. Попробуйте поделиться файлом меньшего размера.';

  @override
  String get receive_anyway => 'Все равно получить';

  @override
  String get generating_codes => 'Генерируем код...';

  @override
  String get send_help_message =>
      'Отсканируйте QR-код с помощью приложения blastQR на том устройстве, на которое вы хотите получить файл';

  @override
  String get scan_help_message =>
      'Для получения файла отсканируйте совместимую последовательность QR-кодов.';

  @override
  String get help => 'Помощь';

  @override
  String get help_title => 'Как использовать blastQR';

  @override
  String get help_title_1 => 'Скачайте blastQR на другие устройства';

  @override
  String get help_message_1_1 =>
      'Скачайте blastQR на любое устройство, с которого вы хотите получать или отправлять файлы. Приложение blastQR должно быть установлено на обоих устройствах.';

  @override
  String get help_message_1_2 =>
      'Отсканируйте QR-код, чтобы загрузить blastQR на другое устройство. Этот конкретный код можно отсканировать с помощью любого стандартного приложения для сканирования QR-кодов. blastQR доступен для Android, iOS, Linux, macOS и Windows.';

  @override
  String get help_title_2 => 'Отправка файла';

  @override
  String get help_message_2 =>
      'На главном экране приложения выберите файл или изображение, которое хотите отправить.\n\nФайл будет закодирован в последовательность QR-кодов, которые вы затем сможете отсканировать с другого устройства, на котором установлено приложение BlastQR.';

  @override
  String get help_title_3 => 'Получение файла';

  @override
  String get help_message_3 =>
      'На другом устройстве отсканируйте последовательность QR-кодов с помощью приложения blastQR, выбрав вкладку «Получить» (Receive).\n\nПолученные файлы сохраняются в приложении на вкладке «Полученные» (Received).\n\nСОВЕТ: Если процесс сканирования внезапно остановился, коснитесь экрана, чтобы возобновить его.';

  @override
  String get help_title_4 => 'дополнительная информация';

  @override
  String get help_message_4 =>
      '- Передача файлов через blastQR осуществляется полностью в автономном режиме (офлайн).\n\n- Передаваемые данные НЕ зашифрованы; любой, кто получит доступ к последовательности QR-кодов, сможет их прочитать (если только не используется функция «Отправить с шифрованием паролем»). Не используйте blastQR для передачи конфиденциальной информации без предварительного включения шифрования и всегда задавайте надежные пароли.\n\n- В силу особенностей технологии, передача файлов через blastQR по умолчанию работает не очень быстро. Однако отображение нескольких кодов одновременно (кнопка полноэкранного режима) и увеличение параметра «Скорость воспроизведения» в настройках позволяют значительно ускорить процесс.\n\n- С помощью blastQR также можно сканировать обычные QR-коды.\n\n- blastQR — это проект с открытым исходным кодом. Исходный код доступен по адресу:';

  @override
  String get settings => 'Настройки';

  @override
  String get appearance => 'Вид';

  @override
  String get language => 'Языки';

  @override
  String get theme => 'Темы';

  @override
  String get theme_system => 'Система';

  @override
  String get theme_light => 'Светлый режим';

  @override
  String get theme_dark => 'Темный режим';

  @override
  String get pure_black => 'Использовать черный цвет';

  @override
  String get accent_color => 'Акцентный цвет';

  @override
  String get animations => 'Анимированный фон';

  @override
  String get enabled => 'Включено';

  @override
  String get disabled => 'Выключено';

  @override
  String get chunk_length => 'Байтов в QR-коде';

  @override
  String get playback_fps => 'Скорость воспроизведения';

  @override
  String get licenses => 'Лицензии';

  @override
  String get source_code => 'Исходный код';

  @override
  String get share_app => 'Поделиться blastQR';

  @override
  String get file_format => 'Формат файла';

  @override
  String get downscaling => 'Уменьшение масштаба';

  @override
  String get camera_resolution =>
      'разрешение изображения в режиме предпросмотра камеры';

  @override
  String get feedback => 'Обратная связь';

  @override
  String get haptic_feedback => 'Тактильная обратная связь';

  @override
  String get sound_feedback => 'Звуковая обратная связь';

  @override
  String get today => 'Сегодня';

  @override
  String get yesterday => 'Вчера';

  @override
  String get filter_all => 'Всё';

  @override
  String get filter_images => 'Фото';

  @override
  String get filter_videos => 'Видео';

  @override
  String get filter_audio => 'Аудию';

  @override
  String get filter_document => 'Документы';

  @override
  String get filter_book => 'Книги';

  @override
  String get filter_other => 'Другое';

  @override
  String get older => 'Старые';

  @override
  String get select_all => 'Выбрать все';

  @override
  String selected(int count) {
    return '$count выбраны';
  }

  @override
  String get delete_files_msg =>
      'Вы уверены, что хотите удалить выбранные файлы?';

  @override
  String files_selected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count файлы выбраны',
      one: '1 файл выбран',
    );
    return '$_temp0';
  }

  @override
  String get file_missing => 'Файл не найден';

  @override
  String file_missing_msg(String name) {
    return '$name было перемещено или удалено.';
  }

  @override
  String get file_too_large => 'Файл слишком большой';

  @override
  String get file_too_large_msg =>
      'Файл превышает лимит в 4 ГБ, поэтому его невозможно отправить.';

  @override
  String get low_speed_warning =>
      'Низкая скорость передачи данных. Измените расположение устройств и зафиксируйте их в неподвижном состоянии для улучшения производительности.';

  @override
  String get send_file => 'Отправить файл';

  @override
  String get send_picture => 'Отправить медиафайлы';

  @override
  String get send_file_subtitle => 'Любой тип файла';

  @override
  String get send_picture_subtitle => 'Из вашей фотобиблиотеки';

  @override
  String get drop_files => 'Перетащите файлы сюда';

  @override
  String get drop_files_subtitle => 'или нажмите, чтобы выбрать';

  @override
  String get desktop_receive_unsupported =>
      '* В Windows пока не поддерживается прием файлов.';

  @override
  String get recent => 'Недавние';

  @override
  String get clear_recent => 'Очистить';

  @override
  String get sending_settings => 'Отправка';

  @override
  String get receiving_settings => 'Получение';

  @override
  String get restore_defaults => 'Восстановить';

  @override
  String get reset_to_default => 'Сбросить до настроек по умолчанию';

  @override
  String get restore_defaults_msg =>
      'Вы уверены, что хотите восстановить эти настройки по умолчанию?';

  @override
  String get qr_codes_section => 'QR коды';

  @override
  String get chunk_length_hint =>
      '2935 байт — рекомендуемое значение для обеспечения наилучшей производительности на большинстве устройств';

  @override
  String get min_code_size => 'Минимальный размер QR-кода';

  @override
  String get min_code_size_hint =>
      'Дополнительные коды отображаются только до тех пор, пока размер каждого из них не превышает этот предел. Уменьшите размер, чтобы разместить больше кодов, увеличьте, если принимающее устройство не может их считать.';

  @override
  String get max_codes => 'Максимальное количество QR-кодов на экране';

  @override
  String get max_codes_hint =>
      'Максимальное количество кодов, отображаемых одновременно. Уменьшите значение, если принимающее устройство не может считать их все.';

  @override
  String get playback_fps_hint =>
      'Рекомендуемое значение для оптимальной производительности на большинстве устройств — 20 кадров в секунду.';

  @override
  String get multi_qr_mode => 'Запустить в полноэкранном режиме';

  @override
  String get multi_qr_mode_subtitle =>
      'Для ускорения работы отобразите на экране как можно больше кодов.';

  @override
  String get compress_media_by_default => 'Сжимать медиафайлы по умолчанию';

  @override
  String get compress_media_by_default_subtitle =>
      'Файлы меньшего размера, которые передаются быстрее, но с более низким качеством.';

  @override
  String get hd_tooltip =>
      'Разрешить отправку фотографий и видео в полном качестве.';

  @override
  String get camera_section => 'Камера';

  @override
  String get camera_resolution_hint =>
      'Большинство устройств будут работать лучше, если установить параметр на «Очень высокое»';

  @override
  String get error => 'Ошибка';

  @override
  String get invalid_downscale_value =>
      'Недопустимое значение (должно быть больше 100)';

  @override
  String downscaling_subtitle(String size) {
    return 'Уменьшение масштаба до ${size}px';
  }

  @override
  String get acoustic_detection => 'Обнаружение сигнала завершения';

  @override
  String get acoustic_detection_subtitle =>
      'Используйте микрофон, чтобы определить завершение передачи файла.';

  @override
  String get acoustic_feedback => 'Звук завершения передачи';

  @override
  String get transfer_complete => 'Передача завершена!';

  @override
  String get keep_showing_qr => 'Показать QR-код еще раз';

  @override
  String get mic_permission_title => 'Автоматическое определение завершено';

  @override
  String get mic_permission_message =>
      'BlastQR может определять завершение передачи, считывая сигнал подтверждения через микрофон. Хотите включить эту функцию?';

  @override
  String get mic_permission_allow => 'Разрешить доступ к микрофону';

  @override
  String get receive_failed_msg =>
      'Файл не удалось сохранить. Возможно, он поврежден или превышает 4 ГБ по размеру.';

  @override
  String get file_too_large_for_qr_size_msg =>
      'Этот файл слишком большой для текущего значения «байт на QR-код». Увеличьте значение «байт на QR-код» в разделе «Настройки» > «Отправка».';

  @override
  String get receiving_generic => 'Получение файла...';

  @override
  String get update_required_title => 'Требуется обновление';

  @override
  String get update_required_msg =>
      'Это сообщение было отправлено с более новой версией blastQR. Обновите приложение, чтобы его получить.';

  @override
  String get sender_update_required_msg =>
      'Это сообщение было отправлено с помощью более старой версии blastQR. Попросите отправителя обновить приложение.';

  @override
  String get send_encrypted => 'Отправка зашифрованного паролем файла';

  @override
  String get receiving_encrypted => 'Получение зашифрованного файла...';

  @override
  String get enter_password => 'Введите пароль';

  @override
  String get enter_password_msg =>
      'Этот файл зашифрован. Введите пароль отправителя.';

  @override
  String get wrong_password => 'Неверный пароль. Попробуйте ещё раз.';

  @override
  String get unlock => 'Разблокировать';

  @override
  String get received_encrypted => 'Получено в зашифрованном виде.';

  @override
  String get show_password => 'Показать пароль';

  @override
  String get password => 'Пароль';

  @override
  String get new_password => 'Новый пароль';

  @override
  String get edit_password => 'Изменить пароль';

  @override
  String password_short_warning(int min) {
    return 'Используйте не менее $min символов.';
  }

  @override
  String get custom_password_title => 'Пользовательский пароль';

  @override
  String get custom_password_msg =>
      'Файл будет зашифрован с помощью следующего пароля.';

  @override
  String files_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count файлы',
      one: '1 файл',
    );
    return '$_temp0';
  }

  @override
  String sending_files_count(int count) {
    return 'Отправка $count файлов';
  }

  @override
  String get debug => 'Отлаживать';

  @override
  String get camera_zoom => 'зум камеры';

  @override
  String get camera_zoom_hint =>
      'Увеличение масштаба позволяет камере считывать коды с большего расстояния, где она всё ещё может сфокусироваться. Это полезно для устройств, которые не могут фокусироваться вблизи.';

  @override
  String get crop_camera_preview =>
      'Предварительный просмотр камеры с кадрированием';

  @override
  String get crop_camera_preview_hint =>
      'Заполняет весь экран, но скрывает края.';

  @override
  String get progress_on_codes => 'Progress overlay';

  @override
  String get progress_on_codes_hint =>
      'Shows a progress bar on top of the scanned QR codes.';

  @override
  String get advanced => 'ещё';

  @override
  String get allow_video_hdr => 'Разрешить воспроизведение видео в формате HDR';

  @override
  String get allow_video_hdr_hint =>
      'По умолчанию отключено. HDR позволяет объединять два кода в один кадр.';

  @override
  String get exposure_time => 'Время выдержки';

  @override
  String get exposure_time_hint =>
      'При длительной выдержке два кода объединяются в один кадр, когда отправитель меняет код в процессе съемки. При фиксированной выдержке повышается ISO для поддержания яркости, поэтому изображение становится более шумным.';

  @override
  String exposure_auto_capped(String ms) {
    return 'Автоматический режим, максимум $ms мс (по умолчанию)';
  }

  @override
  String get exposure_auto => 'Автоматический режим, без ограничений';

  @override
  String exposure_fixed(String ms) {
    return 'Фиксированный $ms мс';
  }

  @override
  String get camera_fps => 'Частота кадров камеры';

  @override
  String get camera_fps_hint =>
      'Более высокая частота обновления экрана дает сканеру больше возможностей для считывания каждого кода. Указаны только те частоты обновления, которые поддерживает данное устройство при текущем разрешении.';

  @override
  String get fps_default => 'По умолчанию';

  @override
  String fps_auto(String fps) {
    return 'Автоматический ($fps FPS)';
  }

  @override
  String get debug_share => 'Поделиться';

  @override
  String get debug_clear => 'Очистить';

  @override
  String get debug_camera => 'Камера';

  @override
  String get debug_device => 'Устройство';

  @override
  String get debug_supported_frame_rates =>
      'Поддерживаемая частота кадров (FPS)';

  @override
  String get debug_save_frames => 'Сохранение выборочных кадров';

  @override
  String get debug_save_frames_hint =>
      'Сохраняет несколько кадров с камеры после каждой передачи, чтобы их можно было просмотреть или поделиться ими.';

  @override
  String get debug_last_transfers => 'Последние переводы';

  @override
  String get debug_no_transfers => 'Пока нет переводов';

  @override
  String get debug_transfers_hint =>
      'Последние 5 переводов сохранены в памяти. Информация о совместном использовании включает все детали. Полезными считаются коды, считанные впервые.';

  @override
  String get debug_unavailable => 'Недоступно';

  @override
  String get debug_status_receiving => 'Получение';

  @override
  String get debug_status_complete => 'Совершенно';

  @override
  String get debug_status_stopped => 'Остановлено';

  @override
  String get debug_useful_codes => 'Полезные коды';

  @override
  String get debug_codes_caught => 'Перехваченные коды';

  @override
  String debug_codes_caught_value(int caught, int shown, String percent) {
    return '$caught из $shown показанных ($percent)';
  }

  @override
  String debug_camera_value(String fps, String percent) {
    return '$fps FPS · $percent кадры с кодом';
  }

  @override
  String get debug_decode => 'Расшифровка';

  @override
  String debug_decode_value(String average, String p95) {
    return '$average сред. · $p95 p95';
  }

  @override
  String get debug_exposure => 'выдержка';

  @override
  String debug_frame_codes(int read, int max) {
    return '$read из $max кодов прочитанны';
  }

  @override
  String get debug_frame_code_read => 'код прочитан';

  @override
  String get debug_frame_no_code => 'код не прочитан';

  @override
  String debug_sample_frames_multi(int max) {
    return 'Примеры кадров (red: fewer than $max codes read)';
  }

  @override
  String get debug_sample_frames => 'Примеры кадров (red: no code read)';

  @override
  String get qr_code => 'QR код';

  @override
  String get filter_qr => 'QR';

  @override
  String scanned_at(String date) {
    return 'Сканирован $date';
  }

  @override
  String get copied => 'Скопирован!';

  @override
  String get files_settings => 'Файлы';

  @override
  String get show_in_files_app => 'Показать в приложении «Файлы»';

  @override
  String get show_in_files_app_hint =>
      'Позволяет открывать полученные файлы из приложения «Файлы», а также из Finder на подключенном Mac.';

  @override
  String get qr_tooltip_fps => 'Изменить скорость воспроизведения';

  @override
  String get qr_tooltip_fullscreen => 'Полный экран';

  @override
  String get qr_tooltip_tone_on =>
      'Прекратить распознавание сигнала завершения';

  @override
  String get qr_tooltip_tone_off =>
      'Уловить сигнал завершения с помощью микрофона.';

  @override
  String get camera_permission_msg =>
      'blastQR не может получить доступ к камере. Разрешите доступ к камере для получения файлов.';

  @override
  String get enable_camera => 'Включить камеру';

  @override
  String compressing_videos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Сжатие $count видео',
      one: 'Сжатие видео',
    );
    return '$_temp0';
  }

  @override
  String time_left_seconds(int seconds) {
    return 'Примерно $seconds осталось';
  }

  @override
  String time_left_minutes(int minutes) {
    return 'Примерно $minutes минут осталось';
  }

  @override
  String get preparing_transfer => 'Подготовка к передаче...';

  @override
  String get send_files_title => 'Отправить файлы';

  @override
  String get photos_and_videos_section => 'Фото и видео';

  @override
  String get video_quality => 'Качество видео';

  @override
  String get video_quality_hint =>
      'Видео сжимается до этого качества, когда HD-режим отключен.';

  @override
  String get video_quality_original => 'Оригинальное качество';

  @override
  String get video_quality_low => 'Низкое (540p)';

  @override
  String get video_quality_lowest => 'Самое низкое (360p)';

  @override
  String get video_quality_potato => 'Качество старого нокия (240p)';

  @override
  String send_time_seconds(int seconds) {
    return 'отправка занимает около $seconds секунд';
  }

  @override
  String send_time_minutes(int minutes) {
    return 'Отправка занимает около $minutes минут';
  }

  @override
  String get stop_sending => 'Прекратить отправку?';

  @override
  String get stop_sending_msg => 'Получатель пока не имеет полный файл.';

  @override
  String get stop => 'Останавить';

  @override
  String get keep_sending => 'Продолжать отправлять';
}
