// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Catalan Valencian (`ca`).
class AppLocalizationsCa extends AppLocalizations {
  AppLocalizationsCa([String locale = 'ca']) : super(locale);

  @override
  String get blast_title => 'BLAST';

  @override
  String get send => 'Envia';

  @override
  String get receive => 'Rep';

  @override
  String get my_files => 'Rebuts';

  @override
  String get ok => 'D\'acord';

  @override
  String get done => 'Fet';

  @override
  String get cancel => 'Cancel·la';

  @override
  String get save => 'Desa';

  @override
  String get discard => 'Descarta';

  @override
  String get copy => 'Copia';

  @override
  String get dismiss => 'Tanca';

  @override
  String get pick_file_msg => 'Tria un fitxer per enviar';

  @override
  String get keep_scanning_msg => 'Continua escanejant!';

  @override
  String get result => 'Resultat';

  @override
  String get file_name => 'Nom del fitxer';

  @override
  String get open => 'Obre';

  @override
  String get rename => 'Reanomena';

  @override
  String get delete => 'Suprimeix';

  @override
  String get delete_msg => 'Segur que vols suprimir aquest fitxer?';

  @override
  String get yes_delete => 'Sí, suprimeix-lo';

  @override
  String get save_to_downloads => 'Desa a Descàrregues';

  @override
  String get file_options => 'Opcions del fitxer';

  @override
  String get no_files_msg => 'Encara no hi ha fitxers.';

  @override
  String get saved_to => 'Desat a';

  @override
  String get received_in => 'Rebut en';

  @override
  String get large_file => 'Fitxer gran';

  @override
  String get large_file_msg_1 =>
      'El fitxer que has seleccionat és gran i podria tardar fins a';

  @override
  String get large_file_msg_2 => 'a transferir-se.';

  @override
  String get large_file_msg_3 =>
      'Vols enviar una versió comprimida de menor qualitat d\'aquesta imatge?';

  @override
  String get minutes => 'minuts';

  @override
  String get image_compression => 'Compressió d\'imatges';

  @override
  String get image_quality => 'Qualitat';

  @override
  String get send_large_file => 'Envia el fitxer original';

  @override
  String get send_compressed_image => 'Envia imatge comprimida';

  @override
  String get to_transfer => 'a transferir';

  @override
  String get generating_codes => 'Generant codis...';

  @override
  String get send_help_message =>
      'Escaneja aquest codi QR amb l\'app blastQR al dispositiu on vols rebre el fitxer';

  @override
  String get scan_help_message =>
      'Per rebre un fitxer, escaneja una seqüència de codis QR compatible';

  @override
  String get help => 'Ajuda';

  @override
  String get help_title => 'Com utilitzar blastQR';

  @override
  String get help_title_1 => 'Baixa blastQR en altres dispositius';

  @override
  String get help_message_1_1 =>
      'Descarrega l\'app blastQR en qualsevol dispositiu on vulguis enviar o rebre fitxers. Tots dos dispositius han de tenir l\'app blastQR.';

  @override
  String get help_message_1_2 =>
      'Escaneja aquest codi QR per descarregar blastQR en un altre dispositiu. Aquest codi es pot escanejar amb qualsevol app de lectura de codis QR. blastQR està disponible a Android, iOS, Linux, macOS i Windows.';

  @override
  String get help_title_2 => 'Enviar un fitxer';

  @override
  String get help_message_2 =>
      'Des de la pantalla principal de l\'app, selecciona el fitxer o la imatge que vols enviar.\n\nEl fitxer es codificarà en una seqüència de codis QR que després podràs escanejar des d\'un altre dispositiu que tingui blastQR instal·lat.';

  @override
  String get help_title_3 => 'Rebre un fitxer';

  @override
  String get help_message_3 =>
      'En un altre dispositiu, escaneja la seqüència de codis QR utilitzant l\'app blastQR seleccionant la pestanya \'Rep\'.\n\nEls fitxers rebuts es guarden a la pestanya \'Rebuts\' dins de l\'app.\n\nCONSELL: Si el procés d\'escaneig s\'atura de sobte, toca la pantalla per continuar.';

  @override
  String get help_title_4 => 'Informació addicional';

  @override
  String get help_message_4 =>
      '- Les transferències de fitxers de blastQR funcionen completament sense connexió a internet.\n\n- La informació transferida NO està encriptada i pot ser llegida per qualsevol que tingui accés a la seqüència de codis QR. Eviteu utilitzar blastQR per transmetre informació sensible.\n\n- A causa de la tecnologia utilitzada, les transferències de fitxers amb blastQR són lentes (amb un màxim d\'uns 110kB/s). Es recomana enviar fitxers petits o comprimir-los abans.\n\n- Per a velocitats més altes, pots modificar el valor de \'Mida codi QR\' a la pantalla de configuració del dispositiu emissor. Pots augmentar la velocitat assignant valors més alts.\n\n- També pots utilitzar blastQR per escanejar codis QR normals.\n\n- blastQR és un projecte de codi obert. Pots trobar el codi font a:';

  @override
  String get settings => 'Configuració';

  @override
  String get appearance => 'Aparença';

  @override
  String get language => 'Idioma';

  @override
  String get theme => 'Estil visual';

  @override
  String get theme_system => 'Sistema';

  @override
  String get theme_light => 'Clar';

  @override
  String get theme_dark => 'Fosc';

  @override
  String get pure_black => 'Utilitza color negre pur';

  @override
  String get accent_color => 'Colorització';

  @override
  String get animations => 'Fons animat';

  @override
  String get enabled => 'Activat';

  @override
  String get disabled => 'Desactivat';

  @override
  String get chunk_length => 'Mida de codi QR';

  @override
  String get playback_fps => 'Velocitat de reproducció';

  @override
  String get licenses => 'Llicències';

  @override
  String get file_format => 'Format de fitxer';

  @override
  String get downscaling => 'Reducció d\'escala';

  @override
  String get camera_resolution => 'Resolució de la càmera';

  @override
  String get feedback => 'Retroacció';

  @override
  String get haptic_feedback => 'Vibració';

  @override
  String get sound_feedback => 'So';

  @override
  String get today => 'Avui';

  @override
  String get yesterday => 'Ahir';

  @override
  String get filter_all => 'Tot';

  @override
  String get filter_images => 'Imatges';

  @override
  String get filter_videos => 'Vídeos';

  @override
  String get filter_audio => 'Àudio';

  @override
  String get filter_document => 'Documents';

  @override
  String get filter_book => 'Llibres';

  @override
  String get filter_other => 'Altres';

  @override
  String get older => 'Anteriors';

  @override
  String get select_all => 'Seleccionar tot';

  @override
  String get selected => 'seleccionats';

  @override
  String get delete_files_msg =>
      'Segur que vols suprimir els fitxers seleccionats?';

  @override
  String get selected_options => 'Fitxers seleccionats';

  @override
  String get file_too_large => 'Fitxer massa gran';

  @override
  String get file_too_large_msg =>
      'Aquest fitxer supera el límit de 4 GB i no es pot enviar';

  @override
  String get low_speed_warning =>
      'Velocitat de transferència baixa. Ajusta la posició dels dispositius i mantén-los quiets per obtenir millor rendiment';

  @override
  String get send_file => 'Envia fitxers';

  @override
  String get send_picture => 'Envia imatges';

  @override
  String get desktop_receive_unsupported =>
      '* La recepció de fitxers encara no és compatible a Windows';

  @override
  String get recent => 'Recents';

  @override
  String get send_selected => 'Envia els seleccionats';

  @override
  String get sending_settings => 'Enviament';

  @override
  String get receiving_settings => 'Recepció';

  @override
  String get restore_defaults => 'Restaura';

  @override
  String get restore_defaults_msg =>
      'Segur que vols restaurar aquesta configuració als seus valors predeterminats?';

  @override
  String get qr_codes_section => 'Codis QR';

  @override
  String get chunk_length_hint =>
      '2935 bytes és el valor recomanat per al millor rendiment a la majoria de dispositius';

  @override
  String get playback_fps_hint =>
      '20 FPS és el valor recomanat per al millor rendiment a la majoria de dispositius';

  @override
  String get multi_qr_mode => 'Inicia en mode multi-QR';

  @override
  String get multi_qr_mode_subtitle =>
      'Mostra tants codis com caben a la pantalla';

  @override
  String get images_section => 'Imatges';

  @override
  String get always_compress_images => 'Comprimir imatges sempre';

  @override
  String get always_compress_images_subtitle =>
      'Omet l\'avís de compressió per a fitxers grans';

  @override
  String get camera_section => 'Càmera';

  @override
  String get camera_resolution_hint =>
      'La majoria de dispositius funcionarà millor amb aquest ajust en \"High\"';

  @override
  String get error => 'Error';

  @override
  String get invalid_downscale_value =>
      'Valor no vàlid (ha de ser superior a 100)';

  @override
  String downscaling_subtitle(String size) {
    return 'Reducció a ${size}px';
  }

  @override
  String get acoustic_detection => 'Detecció acústica';

  @override
  String get acoustic_detection_subtitle =>
      'Detecta la finalització de transferències amb el micròfon';

  @override
  String get acoustic_feedback => 'Finalització de transferències';

  @override
  String get transfer_complete => 'Transferència completa!';

  @override
  String get keep_showing_qr => 'Torna a mostrar el codi QR';

  @override
  String get mic_permission_title => 'Detecció acústica';

  @override
  String get mic_permission_message =>
      'blastQR pot detectar quan una transferència ha finalitzat a través del micròfon. Vols activar aquesta funció?';

  @override
  String get mic_permission_allow => 'Permet accés al micròfon';

  @override
  String get receive_failed_msg =>
      'No s\'ha pogut desar el fitxer. Pot ser que estigui malmès o que superi els 4 GB.';

  @override
  String get file_too_large_for_qr_size_msg =>
      'Aquest fitxer és massa gran per a la mida de codi QR actual. Augmenta la mida del codi QR a Configuració › Enviament.';

  @override
  String get receiving_generic => 'Rebent fitxer...';

  @override
  String get update_required_title => 'Cal actualitzar';

  @override
  String get update_required_msg =>
      'Això s\'ha enviat amb una versió més recent de blastQR. Actualitza l\'aplicació per rebre-ho.';

  @override
  String get send_encrypted => 'Enviar xifrat amb contrasenya';

  @override
  String get receiving_encrypted => 'S\'està rebent un fitxer xifrat...';

  @override
  String get enter_password => 'Introdueix la contrasenya';

  @override
  String get enter_password_msg =>
      'Aquest fitxer està xifrat. Introdueix la contrasenya del remitent.';

  @override
  String get wrong_password => 'Contrasenya incorrecta. Torna-ho a provar.';

  @override
  String get unlock => 'Desbloquejar';

  @override
  String get received_encrypted => 'Rebut xifrat';

  @override
  String get show_password => 'Mostra la contrasenya';

  @override
  String get password => 'Contrasenya';

  @override
  String get new_password => 'Nova contrasenya';

  @override
  String get edit_password => 'Editar la contrasenya';

  @override
  String get password_short_warning =>
      'Les contrasenyes curtes no són segures.';

  @override
  String get custom_password_title => 'Contrasenya personalitzada';

  @override
  String get custom_password_msg =>
      'El fitxer es xifrarà amb la contrasenya següent.';

  @override
  String files_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fitxers',
      one: '1 fitxer',
    );
    return '$_temp0';
  }

  @override
  String sending_files_count(int count) {
    return 'Enviant $count fitxers';
  }
}
