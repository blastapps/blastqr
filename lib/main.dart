import 'package:blast_qr/app_preferences.dart';
import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/file_badge_count.dart';
import 'package:blast_qr/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:blast_qr/features/main_page.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rinf/rinf.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import './messages/all.dart';

void main() async {
  await initializeRust(assignRustSignal);
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

  //Setting SystmeUIMode
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top],
  );

  await AppPreferences.read();

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
      ],
      child: Consumer<AppSettings>(
        builder: (context, state, child) {
          return MaterialApp(
            title: 'blastqr',
            theme: lightTheme,
            darkTheme: state.theme.themeData ?? darkTheme(darkColorScheme),
            themeMode: state.theme.themeMode,
            locale: state.locale,
            home: MainPage(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          );
        },
      ),
    );
  }
}
