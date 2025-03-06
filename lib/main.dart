import 'package:blast_qr/theme.dart';
import 'package:flutter/material.dart';
import 'package:blast_qr/features/main_page.dart';
import 'package:rinf/rinf.dart';

import './messages/all.dart';

void main() async {
  await initializeRust(assignRustSignal);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BlastQR',
      theme: lightTheme,
      darkTheme: darkTheme,
      home: const MainPage(),
    );
  }
}
