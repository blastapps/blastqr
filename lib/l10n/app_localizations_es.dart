// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get blast_title => 'BLAST';

  @override
  String get send => 'Enviar';

  @override
  String get receive => 'Recibir';

  @override
  String get my_files => 'Recibidos';

  @override
  String get ok => 'Aceptar';

  @override
  String get done => 'Hecho';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get discard => 'Descartar';

  @override
  String get copy => 'Copiar';

  @override
  String get dismiss => 'Descartar';

  @override
  String get pick_file_msg => 'Selecciona un archivo para enviar';

  @override
  String get keep_scanning_msg => '¡Sigue escaneando!';

  @override
  String get result => 'Resultado';

  @override
  String get file_name => 'Nombre del archivo';

  @override
  String get open => 'Abrir';

  @override
  String get share => 'Compartir';

  @override
  String get show_in_file_manager => 'Ver en el administrador de archivos';

  @override
  String get rename => 'Renombrar';

  @override
  String get delete => 'Eliminar';

  @override
  String get delete_msg => '¿Estás seguro de que deseas eliminar este archivo?';

  @override
  String get yes_delete => 'Sí, eliminar';

  @override
  String get save_to_downloads => 'Guardar en Descargas';

  @override
  String get save_to_files => 'Guardar en Archivos';

  @override
  String files_saved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos guardados',
      one: '1 archivo guardado',
    );
    return '$_temp0';
  }

  @override
  String get file_options => 'Opciones de archivo';

  @override
  String get no_files_msg => 'Aún no hay archivos.';

  @override
  String get saved_to => 'Guardado en';

  @override
  String get received_in => 'Recibido en';

  @override
  String get large_file => 'Transferencia larga';

  @override
  String get large_file_msg_1 =>
      'Esta transferencia es grande y podría tardar hasta';

  @override
  String get large_file_msg_2 => 'en transferirse.';

  @override
  String get minutes => 'minutos';

  @override
  String get image_compression => 'Compresión de imagen';

  @override
  String get image_quality => 'Calidad';

  @override
  String get send_large_file => 'Enviar de todos modos';

  @override
  String get low_memory => 'Demasiado grande para este dispositivo';

  @override
  String get low_memory_msg =>
      'Probablemente este archivo sea demasiado grande para la memoria de este dispositivo. Es probable que la app se cierre antes de que termine la transferencia. Prueba a compartir un archivo más pequeño.';

  @override
  String get receive_anyway => 'Recibir de todos modos';

  @override
  String get to_transfer => 'para transferir';

  @override
  String get generating_codes => 'Generando códigos...';

  @override
  String get send_help_message =>
      'Escanea este código QR con la app blastQR en el dispositivo donde quieres recibir el archivo.';

  @override
  String get scan_help_message =>
      'Para recibir un archivo, escanea la secuencia de códigos QR desde la pantalla de otro dispositivo';

  @override
  String get help => 'Ayuda';

  @override
  String get help_title => 'Cómo usar blastQR';

  @override
  String get help_title_1 => 'Instala blastQR en otros dispositivos';

  @override
  String get help_message_1_1 =>
      'Descarga la app blastQR en cualquier dispositivo donde quieras enviar o recibir archivos. Ambos dispositivos deben tener la app blastQR.';

  @override
  String get help_message_1_2 =>
      'Escanea este código QR para descargar blastQR en otro dispositivo. Este código puede ser escaneado con cualquier app de lectura de códigos QR. blastQR está disponible en Android, iOS, Linux, macOS y Windows.';

  @override
  String get help_title_2 => 'Enviar un archivo';

  @override
  String get help_message_2 =>
      'Desde la pantalla principal de la app, selecciona el archivo o imagen que deseas enviar.\n\nEl archivo se codificará en una secuencia de códigos QR que luego podrás escanear desde otro dispositivo que tenga blastQR instalado.';

  @override
  String get help_title_3 => 'Recibir un archivo';

  @override
  String get help_message_3 =>
      'En otro dispositivo, escanea la secuencia de códigos QR utilizando la app blastQR seleccionando la pestaña \'Recibir\'.\n\nLos archivos recibidos se guardan en la pestaña \'Archivos\' dentro de la app.\n\nCONSEJO: Si el proceso de escaneo se detiene repentinamente, toca la pantalla para continuar.';

  @override
  String get help_title_4 => 'Información adicional';

  @override
  String get help_message_4 =>
      '- Las transferencias de archivos de blastQR funcionan completamente sin conexión.\n\n- La información transferida NO está encriptada y puede ser leída por cualquiera que tenga acceso a la secuencia de códigos QR, a menos que uses la función \'Enviar cifrado con contraseña\'. Evita usar blastQR para transmitir información sensible sin activar antes el cifrado y usa siempre contraseñas seguras.\n\n- Debido a la tecnología utilizada, las transferencias de archivos con blastQR no son muy rápidas por defecto. Sin embargo, mostrar varios códigos a la vez (botón de pantalla completa) y aumentar la \'Velocidad de reproducción\' en la Configuración puede aumentar mucho la velocidad.\n\n- También puedes usar blastQR para escanear códigos QR normales.\n\n- blastQR es un proyecto de código abierto. Puedes encontrar el código fuente en:';

  @override
  String get settings => 'Configuración';

  @override
  String get appearance => 'Apariencia';

  @override
  String get language => 'Idioma';

  @override
  String get theme => 'Tema';

  @override
  String get theme_system => 'Sistema';

  @override
  String get theme_light => 'Claro';

  @override
  String get theme_dark => 'Oscuro';

  @override
  String get pure_black => 'Usar color negro puro';

  @override
  String get accent_color => 'Color de acento';

  @override
  String get animations => 'Fondo animado';

  @override
  String get enabled => 'Activado';

  @override
  String get disabled => 'Desactivado';

  @override
  String get chunk_length => 'Tamaño código QR';

  @override
  String get playback_fps => 'Velocidad de reproducción';

  @override
  String get licenses => 'Licencias';

  @override
  String get source_code => 'Código fuente';

  @override
  String get share_app => 'Compartir blastQR';

  @override
  String get file_format => 'Formato de archivo';

  @override
  String get downscaling => 'Reducción de escala';

  @override
  String get camera_resolution => 'Resolución de la cámara';

  @override
  String get feedback => 'Retroalimentación';

  @override
  String get haptic_feedback => 'Respuesta háptica';

  @override
  String get sound_feedback => 'Respuesta de sonido';

  @override
  String get today => 'Hoy';

  @override
  String get yesterday => 'Ayer';

  @override
  String get filter_all => 'Todo';

  @override
  String get filter_images => 'Imágenes';

  @override
  String get filter_videos => 'Vídeos';

  @override
  String get filter_audio => 'Audio';

  @override
  String get filter_document => 'Documentos';

  @override
  String get filter_book => 'Libros';

  @override
  String get filter_other => 'Otros';

  @override
  String get older => 'Anteriores';

  @override
  String get select_all => 'Seleccionar todo';

  @override
  String get selected => 'seleccionados';

  @override
  String get delete_files_msg =>
      '¿Estás seguro de que deseas eliminar los archivos seleccionados?';

  @override
  String files_selected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos seleccionados',
      one: '1 archivo seleccionado',
    );
    return '$_temp0';
  }

  @override
  String get file_missing => 'Archivo no encontrado';

  @override
  String file_missing_msg(String name) {
    return '$name se ha movido o eliminado.';
  }

  @override
  String get file_too_large => 'Archivo demasiado grande';

  @override
  String get file_too_large_msg =>
      'Este archivo supera el límite de 4 GB y no se puede enviar';

  @override
  String get low_speed_warning =>
      'Velocidad de transferencia baja. Ajusta la posición de los dispositivos y mantenlos quietos para obtener mejor rendimiento';

  @override
  String get send_file => 'Enviar Archivos';

  @override
  String get send_picture => 'Enviar fotos y vídeos';

  @override
  String get send_file_subtitle => 'Cualquier tipo de archivo';

  @override
  String get send_picture_subtitle => 'De tu galería de fotos';

  @override
  String get drop_files => 'Suelta los archivos aquí';

  @override
  String get drop_files_subtitle => 'o haz clic para elegirlos';

  @override
  String get desktop_receive_unsupported =>
      '* La recepción de archivos aún no es compatible en Windows';

  @override
  String get recent => 'Recientes';

  @override
  String get clear_recent => 'Borrar';

  @override
  String get sending_settings => 'Envío';

  @override
  String get receiving_settings => 'Recepción';

  @override
  String get restore_defaults => 'Restaurar';

  @override
  String get reset_to_default => 'Restablecer el valor predeterminado';

  @override
  String get restore_defaults_msg =>
      '¿Estás seguro de que deseas restaurar esta configuración a sus valores predeterminados?';

  @override
  String get qr_codes_section => 'Códigos QR';

  @override
  String get chunk_length_hint =>
      '2935 bytes es el valor recomendado para el mejor rendimiento en la mayoría de dispositivos';

  @override
  String get playback_fps_hint =>
      '20 FPS es el valor recomendado para el mejor rendimiento en la mayoría de dispositivos';

  @override
  String get multi_qr_mode => 'Iniciar en pantalla completa';

  @override
  String get multi_qr_mode_subtitle =>
      'Muestra tantos códigos como quepan en pantalla para ir más rápido';

  @override
  String get compress_media_by_default => 'Comprimir multimedia por defecto';

  @override
  String get compress_media_by_default_subtitle =>
      'Archivos más pequeños que se envían más rápido, con menos calidad';

  @override
  String get hd_tooltip =>
      'Actívalo para enviar las fotos y los vídeos en calidad completa';

  @override
  String get camera_section => 'Cámara';

  @override
  String get camera_resolution_hint =>
      'La mayoría de dispositivos funcionarán mejor con este ajuste en \"High\"';

  @override
  String get error => 'Error';

  @override
  String get invalid_downscale_value =>
      'Valor no válido (debe ser mayor que 100)';

  @override
  String downscaling_subtitle(String size) {
    return 'Reducción a ${size}px';
  }

  @override
  String get acoustic_detection => 'Detectar tono de finalización';

  @override
  String get acoustic_detection_subtitle =>
      'Usa el micrófono para detectar cuándo ha terminado una transferencia de archivos';

  @override
  String get acoustic_feedback => 'Tono de finalización de transferencia';

  @override
  String get transfer_complete => '¡Transferencia completa!';

  @override
  String get keep_showing_qr => 'Mostrar el código QR de nuevo';

  @override
  String get mic_permission_title => 'Detección acústica';

  @override
  String get mic_permission_message =>
      'blastQR puede detectar cuándo el otro dispositivo ha recibido un archivo escuchando el tono de finalización a través del micrófono. ¿Quieres activar esta función?';

  @override
  String get mic_permission_allow => 'Permitir acceso al micrófono';

  @override
  String get receive_failed_msg =>
      'No se ha podido guardar el archivo. Puede que esté dañado o que supere los 4 GB.';

  @override
  String get file_too_large_for_qr_size_msg =>
      'Este archivo es demasiado grande para el tamaño de código QR actual. Aumenta el tamaño del código QR en Configuración › Envío.';

  @override
  String get receiving_generic => 'Recibiendo archivo...';

  @override
  String get update_required_title => 'Actualización necesaria';

  @override
  String get update_required_msg =>
      'Esto se ha enviado con una versión más reciente de blastQR. Actualiza la aplicación para recibirlo.';

  @override
  String get sender_update_required_msg =>
      'Esto se ha enviado con una versión antigua de blastQR. Pide a quien lo envía que actualice la aplicación.';

  @override
  String get send_encrypted => 'Enviar cifrado con contraseña';

  @override
  String get receiving_encrypted => 'Recibiendo archivo cifrado...';

  @override
  String get enter_password => 'Introducir contraseña';

  @override
  String get enter_password_msg =>
      'Este archivo está cifrado. Introduce la contraseña del remitente.';

  @override
  String get wrong_password => 'Contraseña incorrecta. Inténtalo de nuevo.';

  @override
  String get unlock => 'Desbloquear';

  @override
  String get received_encrypted => 'Recibido cifrado';

  @override
  String get show_password => 'Mostrar contraseña';

  @override
  String get password => 'Contraseña';

  @override
  String get new_password => 'Nueva contraseña';

  @override
  String get edit_password => 'Editar contraseña';

  @override
  String password_short_warning(int min) {
    return 'Usa al menos $min caracteres.';
  }

  @override
  String get custom_password_title => 'Contraseña personalizada';

  @override
  String get custom_password_msg =>
      'El archivo se cifrará con la siguiente contraseña.';

  @override
  String files_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos',
      one: '1 archivo',
    );
    return '$_temp0';
  }

  @override
  String sending_files_count(int count) {
    return 'Enviando $count archivos';
  }

  @override
  String get debug => 'Depuración';

  @override
  String get camera_zoom => 'Zoom de la cámara';

  @override
  String get camera_zoom_hint =>
      'Hacer zoom permite leer los códigos desde más lejos, donde la cámara aún puede enfocar. Ayuda en móviles que no enfocan de cerca.';

  @override
  String get crop_camera_preview => 'Recortar vista de la cámara';

  @override
  String get crop_camera_preview_hint =>
      'Llena la pantalla pero oculta los bordes.';

  @override
  String get advanced => 'Avanzado';

  @override
  String get allow_video_hdr => 'Permitir vídeo HDR';

  @override
  String get allow_video_hdr_hint =>
      'Desactivado por defecto. El HDR puede mezclar dos códigos en un mismo fotograma.';

  @override
  String get exposure_time => 'Tiempo de exposición';

  @override
  String get exposure_time_hint =>
      'Las exposiciones largas mezclan dos códigos en un fotograma cuando el emisor cambia de código durante la captura. Una exposición fija sube el ISO para mantener el brillo, así que la imagen tiene más ruido.';

  @override
  String exposure_auto_capped(String ms) {
    return 'Automático, máx. $ms ms (por defecto)';
  }

  @override
  String get exposure_auto => 'Automático, sin límite';

  @override
  String exposure_fixed(String ms) {
    return 'Fijo $ms ms';
  }

  @override
  String get camera_fps => 'FPS de la cámara';

  @override
  String get camera_fps_hint =>
      'Más fotogramas dan al escáner más oportunidades de leer cada código. Solo se muestran los que admite este móvil con la resolución actual.';

  @override
  String get fps_default => 'Por defecto';

  @override
  String fps_auto(String fps) {
    return 'Automático ($fps FPS)';
  }

  @override
  String get debug_share => 'Compartir';

  @override
  String get debug_clear => 'Borrar';

  @override
  String get debug_camera => 'Cámara';

  @override
  String get debug_device => 'Dispositivo';

  @override
  String get debug_supported_frame_rates => 'FPS admitidos';

  @override
  String get debug_save_frames => 'Guardar fotogramas de muestra';

  @override
  String get debug_save_frames_hint =>
      'Guarda algunos fotogramas de la cámara por transferencia, para verlos o compartirlos.';

  @override
  String get debug_last_transfers => 'Últimas transferencias';

  @override
  String get debug_no_transfers => 'Aún no hay transferencias';

  @override
  String get debug_transfers_hint =>
      'Las últimas 5 transferencias, guardadas en memoria. Al compartir se incluyen todos los detalles. Los códigos útiles son los que se leen por primera vez.';

  @override
  String get debug_unavailable => 'No disponible';

  @override
  String get debug_status_receiving => 'Recibiendo';

  @override
  String get debug_status_complete => 'Completada';

  @override
  String get debug_status_stopped => 'Detenida';

  @override
  String get debug_useful_codes => 'Códigos útiles';

  @override
  String get debug_codes_caught => 'Códigos captados';

  @override
  String debug_codes_caught_value(int caught, int shown, String percent) {
    return '$caught de $shown mostrados ($percent)';
  }

  @override
  String debug_camera_value(String fps, String percent) {
    return '$fps FPS · $percent de los fotogramas con un código';
  }

  @override
  String get debug_decode => 'Decodificación';

  @override
  String debug_decode_value(String average, String p95) {
    return '$average de media · $p95 p95';
  }

  @override
  String get debug_exposure => 'Exposición';

  @override
  String debug_frame_codes(int read, int max) {
    return '$read de $max códigos leídos';
  }

  @override
  String get debug_frame_code_read => 'código leído';

  @override
  String get debug_frame_no_code => 'ningún código leído';

  @override
  String debug_sample_frames_multi(int max) {
    return 'Fotogramas de muestra (rojo: menos de $max códigos leídos)';
  }

  @override
  String get debug_sample_frames =>
      'Fotogramas de muestra (rojo: ningún código leído)';

  @override
  String get qr_code => 'Código QR';

  @override
  String get filter_qr => 'QR';

  @override
  String scanned_at(String date) {
    return 'Escaneado el $date';
  }

  @override
  String get copied => '¡Copiado!';

  @override
  String get files_settings => 'Archivos';

  @override
  String get show_in_files_app => 'Mostrar en la app Archivos';

  @override
  String get show_in_files_app_hint =>
      'Permite abrir los archivos recibidos desde la app Archivos y desde el Finder de un Mac conectado.';

  @override
  String get qr_tooltip_fps => 'Cambiar la velocidad de reproducción';

  @override
  String get qr_tooltip_fullscreen => 'Pantalla completa';

  @override
  String get qr_tooltip_tone_on => 'Dejar de detectar el tono de finalización';

  @override
  String get qr_tooltip_tone_off =>
      'Detectar el tono de finalización con el micrófono';

  @override
  String get camera_permission_msg =>
      'blastQR no puede acceder a la cámara. Permite el acceso a la cámara para recibir archivos.';

  @override
  String get enable_camera => 'Activar cámara';

  @override
  String compressing_videos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Comprimiendo $count vídeos',
      one: 'Comprimiendo vídeo',
    );
    return '$_temp0';
  }

  @override
  String time_left_seconds(int seconds) {
    return 'Quedan unos $seconds s';
  }

  @override
  String time_left_minutes(int minutes) {
    return 'Quedan unos $minutes min';
  }

  @override
  String get preparing_transfer => 'Preparando la transferencia...';

  @override
  String get send_files_title => 'Enviar archivos';

  @override
  String get photos_and_videos_section => 'Fotos y vídeos';

  @override
  String get video_quality => 'Calidad de vídeo';

  @override
  String get video_quality_hint =>
      'Los vídeos se comprimen a esta calidad cuando HD está desactivado';

  @override
  String get video_quality_original => 'Original';

  @override
  String get video_quality_low => 'Baja (540p)';

  @override
  String get video_quality_lowest => 'Mínima (360p)';

  @override
  String get video_quality_potato => 'Patata (240p)';

  @override
  String send_time_seconds(int seconds) {
    return 'Unos $seconds s para enviar';
  }

  @override
  String send_time_minutes(int minutes) {
    return 'Unos $minutes min para enviar';
  }

  @override
  String get stop_sending => '¿Dejar de enviar?';

  @override
  String get stop_sending_msg => 'El receptor aún no tiene todo el archivo.';

  @override
  String get stop => 'Detener';

  @override
  String get keep_sending => 'Seguir enviando';
}
