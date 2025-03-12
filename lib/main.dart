import 'package:blast_qr/file_badge_count.dart';
import 'package:blast_qr/theme.dart';
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

  //Setting SystmeUIMode
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top],
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => FileBadgeCount(value: null),
      child: MaterialApp(
        title: 'blastqr',
        theme: lightTheme,
        darkTheme: darkTheme,
        home: MainPage(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}
