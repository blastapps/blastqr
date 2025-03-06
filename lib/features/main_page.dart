import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/widgets/logo_widget.dart';
import 'package:flutter/material.dart';
import 'package:blast_qr/features/collection_page.dart';
import 'package:blast_qr/features/send_page.dart';
import 'package:blast_qr/features/scan_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: LogoWidget(), centerTitle: true),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) {
          setState(() {
            _currentTab = index;
          });
        },
        currentIndex: _currentTab,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_outlined),
            activeIcon: Icon(Icons.qr_code, color: context.color.onSurface),
            label: 'Send',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            activeIcon: Icon(Icons.camera_alt, color: context.color.onSurface),
            label: 'Receive',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder, color: context.color.onSurface),
            label: 'My Files',
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          switch (_currentTab) {
            case 0:
              return SendPage();
            case 1:
              return ScanPage();
            case 2:
              return CollectionPage();
          }
          return SizedBox();
        },
      ),
    );
  }
}
