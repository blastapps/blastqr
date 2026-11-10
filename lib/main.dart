import 'package:blast_qr/app_preferences.dart';
import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/features/home_tabs_page.dart';
import 'package:blast_qr/file_badge_count.dart';
import 'package:blast_qr/l10n/app_localizations.dart';
import 'package:blast_qr/nav_bar_visibility.dart';
import 'package:blast_qr/platform_support.dart';
import 'package:blast_qr/received_files_directory.dart';
import 'package:blast_qr/theme.dart';
import 'package:blast_qr/widgets/selection_bar.dart';
import 'package:blastqr_crypto/blastqr_crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:raptorq_flutter/raptorq_flutter.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Additional licenses
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('fonts/Jersey25/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Jersey 25'], license);
  });
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/licenses/raptorq.txt');
    yield LicenseEntryWithLineBreaks(['raptorq'], license);
  });
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString(
      'assets/licenses/rustcrypto.txt',
    );
    yield LicenseEntryWithLineBreaks([
      'argon2',
      'chacha20poly1305',
      'rand_core',
      'zeroize',
    ], license);
  });
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/licenses/subtle.txt');
    yield LicenseEntryWithLineBreaks(['subtle'], license);
  });

  //Setting SystmeUIMode
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top],
  );

  if (isDesktopOS) await windowManager.ensureInitialized();

  await AppPreferences.read();
  await syncReceivedFiles().catchError((Object error) {
    debugPrint('Failed to set up received files: $error');
  });
  await RaptorQFlutter.init().timeout(
    const Duration(seconds: 1),
    onTimeout: () {
      debugPrint('RaptorQFlutter.init() timed out!');
    },
  );
  await BlastqrCrypto.init().timeout(
    const Duration(seconds: 1),
    onTimeout: () {
      debugPrint('BlastqrCrypto.init() timed out!');
    },
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppSettings>(create: (context) => AppSettings()),
        ChangeNotifierProvider<EncodeSettings>(
          create: (context) => EncodeSettings(),
        ),
        ChangeNotifierProvider<FileBadgeCount>(
          create: (context) => FileBadgeCount(value: null),
        ),
        ChangeNotifierProvider<NavBarVisibility>(
          create: (context) => NavBarVisibility(),
        ),
        ChangeNotifierProvider<SelectionBarController>(
          create: (context) => SelectionBarController(),
        ),
      ],
      child: Consumer<AppSettings>(
        builder: (context, state, child) {
          return MaterialApp(
            title: 'blastQR',
            theme: BlastTheme.light.buildTheme(state.accentColor, false),
            darkTheme: BlastTheme.dark.buildTheme(
              state.accentColor,
              state.pureBlack,
            ),
            themeMode: state.theme,
            locale: state.locale,
            home: const HomeTabsPage(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          );
        },
      ),
    );
  }
}
