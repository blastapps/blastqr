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
  String get file_options => 'Opciones de archivo';

  @override
  String get no_files_msg => 'Aún no hay archivos.';

  @override
  String get saved_to => 'Guardado en';

  @override
  String get received_in => 'Recibido en';

  @override
  String get large_file => 'Archivo grande';

  @override
  String get large_file_msg_1 =>
      'El archivo que seleccionaste es grande y podría tardar hasta';

  @override
  String get large_file_msg_2 => 'en transferirse.';

  @override
  String get large_file_msg_3 =>
      'Would you like to send a compresed, lower quality version of this image?';

  @override
  String get minutes => 'minutos';

  @override
  String get image_compression_settings => 'Picture compression settings';

  @override
  String get image_quality => 'Image quality';

  @override
  String get send_large_file => 'Send large file anyway';

  @override
  String get send_compressed_image => 'Send compressed image file';

  @override
  String get to_transfer => 'para transferir';

  @override
  String get generating_codes => 'Generando códigos...';

  @override
  String get send_help_message =>
      'Escanea este código QR con la app blastQR en el dispositivo donde quieres recibir el archivo.';

  @override
  String get scan_help_message =>
      'Para recibir un archivo, escanea la secuencia de códigos QR desde la pantalla de otro dispositivo que use blastQR.';

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
      '- Las transferencias de archivos de blastQR funcionan completamente sin conexión.\n\n- La información transferida NO está encriptada y puede ser leída por cualquiera que tenga acceso a la secuencia de códigos QR. Evita usar esta aplicación para transmitir información sensible.\n\n- Debido a la tecnología utilizada, las transferencias de archivos con blastQR son lentas (alcanzando un máximo de aproximadamente 40kB/s). Se recomienda enviar archivos pequeños o comprimirlos previamente.\n\n- Para obtener velocidades más altas, puedes modificar el valor de \'Longitud del fragmento\' en la pantalla de configuración del dispositivo emisor. Un valor más alto puede aumentar la velocidad, pero no todos los dispositivos pueden manejarlo.\n\n- También puedes usar blastQR para escanear códigos QR normales.\n\n- blastQR es un proyecto de código abierto. Puedes encontrar el código fuente en:';

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
  String get chunk_length => 'Longitud del fragmento';

  @override
  String get licenses => 'Licencias';

  @override
  String get file_format => 'File format';

  @override
  String get keep_original_file_format => 'Keep original file format';
}
