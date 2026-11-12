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
  String get share => 'Comparteix';

  @override
  String get show_in_file_manager => 'Mostra al gestor de fitxers';

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
  String get large_file => 'Transferència llarga';

  @override
  String get large_file_msg_1 =>
      'Aquesta transferència és gran i podria tardar fins a';

  @override
  String get large_file_msg_2 => 'a transferir-se.';

  @override
  String large_file_msg_3(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Vols enviar versions comprimides de menor qualitat d\'aquestes $count imatges?',
      one:
          'Vols enviar una versió comprimida de menor qualitat d\'aquesta imatge?',
    );
    return '$_temp0';
  }

  @override
  String get minutes => 'minuts';

  @override
  String get image_compression => 'Compressió d\'imatges';

  @override
  String get image_quality => 'Qualitat';

  @override
  String get send_large_file => 'Envia igualment';

  @override
  String get send_compressed_image => 'Envia comprimida';

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
      '- Les transferències de fitxers de blastQR funcionen completament sense connexió a internet.\n\n- La informació transferida NO està encriptada i pot ser llegida per qualsevol que tingui accés a la seqüència de codis QR, tret que s\'utilitzi la funció \'Enviar xifrat amb contrasenya\'. Eviteu utilitzar blastQR per transmetre informació sensible sense activar abans el xifratge i utilitzeu sempre contrasenyes segures.\n\n- A causa de la tecnologia utilitzada, les transferències de fitxers amb blastQR no són gaire ràpides per defecte. Tot i així, mostrar diversos codis alhora (botó de pantalla completa) i augmentar la \'Velocitat de reproducció\' a la Configuració pot augmentar molt la velocitat.\n\n- També pots utilitzar blastQR per escanejar codis QR normals.\n\n- blastQR és un projecte de codi obert. Pots trobar el codi font a:';

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
  String get source_code => 'Codi font';

  @override
  String get share_app => 'Compartir blastQR';

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
  String files_selected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fitxers seleccionats',
      one: '1 fitxer seleccionat',
    );
    return '$_temp0';
  }

  @override
  String get file_missing => 'No s\'ha trobat el fitxer';

  @override
  String file_missing_msg(String name) {
    return '$name s\'ha mogut o eliminat.';
  }

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
  String get send_picture => 'Envia fotos i vídeos';

  @override
  String get send_file_subtitle => 'Qualsevol tipus de fitxer';

  @override
  String get send_picture_subtitle => 'De la teva galeria de fotos';

  @override
  String get drop_files => 'Deixa anar els fitxers aquí';

  @override
  String get drop_files_subtitle => 'o fes clic per triar-los';

  @override
  String get desktop_receive_unsupported =>
      '* La recepció de fitxers encara no és compatible a Windows';

  @override
  String get recent => 'Recents';

  @override
  String get clear_recent => 'Esborra';

  @override
  String get sending_settings => 'Enviament';

  @override
  String get receiving_settings => 'Recepció';

  @override
  String get restore_defaults => 'Restaura';

  @override
  String get reset_to_default => 'Restableix el valor per defecte';

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
  String get multi_qr_mode => 'Inicia en pantalla completa';

  @override
  String get multi_qr_mode_subtitle =>
      'Mostra tants codis com càpiguen a la pantalla per anar més ràpid';

  @override
  String get images_section => 'Imatges';

  @override
  String get compress_photos_by_default => 'Comprimir fotos per defecte';

  @override
  String get compress_photos_by_default_subtitle =>
      'Activa HD en enviar per mantenir la qualitat original';

  @override
  String get hd_tooltip =>
      'Activa-ho per enviar les fotos amb qualitat completa';

  @override
  String get camera_section => 'Càmera';

  @override
  String get camera_resolution_hint =>
      '\"High\" és el valor recomanat per al millor rendiment a la majoria de dispositius';

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
  String get acoustic_detection => 'Detecta el to de finalització';

  @override
  String get acoustic_detection_subtitle =>
      'Utilitza el micròfon per detectar quan ha acabat una transferència de fitxers';

  @override
  String get acoustic_feedback => 'To de finalització de transferència';

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
  String get sender_update_required_msg =>
      'Això s\'ha enviat amb una versió antiga de blastQR. Demana a qui ho envia que actualitzi l\'aplicació.';

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
  String password_short_warning(int min) {
    return 'Fes servir almenys $min caràcters.';
  }

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

  @override
  String get debug => 'Depuració';

  @override
  String get camera_zoom => 'Zoom de la càmera';

  @override
  String get camera_zoom_hint =>
      'Fer zoom permet llegir els codis des de més lluny, on la càmera encara pot enfocar. Ajuda en mòbils que no enfoquen de prop.';

  @override
  String get crop_camera_preview => 'Retallar la vista de la càmera';

  @override
  String get crop_camera_preview_hint =>
      'Omple la pantalla però amaga les vores.';

  @override
  String get advanced => 'Avançat';

  @override
  String get allow_video_hdr => 'Permet el vídeo HDR';

  @override
  String get allow_video_hdr_hint =>
      'Desactivat per defecte. L\'HDR pot barrejar dos codis en un mateix fotograma.';

  @override
  String get exposure_time => 'Temps d\'exposició';

  @override
  String get exposure_time_hint =>
      'Les exposicions llargues barregen dos codis en un fotograma quan l\'emissor canvia de codi durant la captura. Una exposició fixa puja l\'ISO per mantenir la brillantor, així que la imatge té més soroll.';

  @override
  String exposure_auto_capped(String ms) {
    return 'Automàtic, màx. $ms ms (per defecte)';
  }

  @override
  String get exposure_auto => 'Automàtic, sense límit';

  @override
  String exposure_fixed(String ms) {
    return 'Fix $ms ms';
  }

  @override
  String get camera_fps => 'FPS de la càmera';

  @override
  String get camera_fps_hint =>
      'Més fotogrames donen a l\'escàner més oportunitats de llegir cada codi. Només es mostren els que admet aquest mòbil amb la resolució actual.';

  @override
  String get fps_default => 'Per defecte';

  @override
  String fps_auto(String fps) {
    return 'Automàtic ($fps FPS)';
  }

  @override
  String get debug_share => 'Comparteix';

  @override
  String get debug_clear => 'Esborra';

  @override
  String get debug_camera => 'Càmera';

  @override
  String get debug_device => 'Dispositiu';

  @override
  String get debug_supported_frame_rates => 'FPS admesos';

  @override
  String get debug_save_frames => 'Desa fotogrames de mostra';

  @override
  String get debug_save_frames_hint =>
      'Desa uns quants fotogrames de la càmera per transferència, per veure\'ls o compartir-los.';

  @override
  String get debug_last_transfers => 'Últimes transferències';

  @override
  String get debug_no_transfers => 'Encara no hi ha transferències';

  @override
  String get debug_transfers_hint =>
      'Les últimes 5 transferències, desades a la memòria. En compartir s\'hi inclouen tots els detalls. Els codis útils són els que es llegeixen per primer cop.';

  @override
  String get debug_unavailable => 'No disponible';

  @override
  String get debug_status_receiving => 'Rebent';

  @override
  String get debug_status_complete => 'Completada';

  @override
  String get debug_status_stopped => 'Aturada';

  @override
  String get debug_useful_codes => 'Codis útils';

  @override
  String get debug_codes_caught => 'Codis captats';

  @override
  String debug_codes_caught_value(int caught, int shown, String percent) {
    return '$caught de $shown mostrats ($percent)';
  }

  @override
  String debug_camera_value(String fps, String percent) {
    return '$fps FPS · $percent dels fotogrames amb un codi';
  }

  @override
  String get debug_decode => 'Descodificació';

  @override
  String debug_decode_value(String average, String p95) {
    return '$average de mitjana · $p95 p95';
  }

  @override
  String get debug_exposure => 'Exposició';

  @override
  String debug_frame_codes(int read, int max) {
    return '$read de $max codis llegits';
  }

  @override
  String get debug_frame_code_read => 'codi llegit';

  @override
  String get debug_frame_no_code => 'cap codi llegit';

  @override
  String debug_sample_frames_multi(int max) {
    return 'Fotogrames de mostra (vermell: menys de $max codis llegits)';
  }

  @override
  String get debug_sample_frames =>
      'Fotogrames de mostra (vermell: cap codi llegit)';

  @override
  String get qr_code => 'Codi QR';

  @override
  String get filter_qr => 'QR';

  @override
  String scanned_at(String date) {
    return 'Escanejat el $date';
  }

  @override
  String get copied => 'Copiat!';

  @override
  String get files_settings => 'Fitxers';

  @override
  String get show_in_files_app => 'Mostra a l\'app Fitxers';

  @override
  String get show_in_files_app_hint =>
      'Permet obrir els fitxers rebuts des de l\'app Fitxers i des del Finder d\'un Mac connectat.';

  @override
  String get qr_tooltip_fps => 'Canvia la velocitat de reproducció';

  @override
  String get qr_tooltip_fullscreen => 'Pantalla completa';

  @override
  String get qr_tooltip_tone_on => 'Deixa de detectar el to de finalització';

  @override
  String get qr_tooltip_tone_off =>
      'Detecta el to de finalització amb el micròfon';

  @override
  String get camera_permission_msg =>
      'blastQR no pot accedir a la càmera. Permet l\'accés a la càmera per rebre fitxers.';

  @override
  String get enable_camera => 'Activa la càmera';
}
