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
      'El fitxer que has seleccionat és gran i podria trigar fins a';

  @override
  String get large_file_msg_2 => 'a transferir-se.';

  @override
  String get large_file_msg_3 =>
      'Would you like to send a compresed, lower quality version of this image?';

  @override
  String get minutes => 'minuts';

  @override
  String get send_large_file => 'Send large file anyway';

  @override
  String get send_compressed_image => 'Send compressed image file';

  @override
  String get to_transfer => 'a transferir';

  @override
  String get generating_codes => 'Generant codis...';

  @override
  String get send_help_message =>
      'Escaneja aquest codi QR amb l\'app blastQR al dispositiu on vols rebre el fitxer.';

  @override
  String get scan_help_message =>
      'Per rebre un fitxer, escaneja la seqüència de codis QR de la pantalla d\'un altre dispositiu que utilitzi blastQR.';

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
      '- Les transferències de fitxers de blastQR funcionen completament sense connexió a internet.\n\n- La informació transferida NO està encriptada i pot ser llegida per qualsevol que tingui accés a la seqüència de codis QR. Eviteu utilitzar blastQR per transmetre informació sensible.\n\n- A causa de la tecnologia utilitzada, les transferències de fitxers amb blastQR són lentes (amb un màxim d\'uns 40kB/s). Es recomana enviar fitxers petits o comprimir-los abans.\n\n- Per a velocitats més altes, pots modificar el valor de \'Longitud per fragment\' a la pantalla de configuració del dispositiu emissor. Pots augmentar la velocitat assignant valors més alts.\n\n- També pots utilitzar blastQR per escanejar codis QR normals.\n\n- blastQR és un projecte de codi obert. Pots trobar el codi font a:';

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
  String get animations => 'Animacions';

  @override
  String get enabled => 'Activat';

  @override
  String get disabled => 'Desactivat';

  @override
  String get data_encoding => 'Codificació de dades';

  @override
  String get chunk_length => 'Longitud per fragment';

  @override
  String get licenses => 'Llicències';
}
