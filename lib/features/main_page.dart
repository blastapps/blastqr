import 'dart:io';

import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/file_badge_count.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:flutter/material.dart';
import 'package:blast_qr/features/files_page.dart';
import 'package:blast_qr/features/send_page.dart';
import 'package:blast_qr/features/scan_page.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(color: context.color.surface),
        Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            image: DecorationImage(
              colorFilter: ColorFilter.mode(
                context.color.primary,
                BlendMode.srcATop,
              ),
              fit: BoxFit.cover,
              opacity:
                  Theme.of(context).brightness == Brightness.dark ? 0.4 : 0.1,
              image: AssetImage('assets/bg_qr.webp'),
            ),
          ),
          height: 400,
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: FractionalOffset(0.5, 0.0),
              end: FractionalOffset(0.5, 1.5),
              colors: [
                context.color.surface,
                context.color.surface.withAlpha(0),
              ],
            ),
          ),
          height: 400,
        ),
        Scaffold(
          extendBodyBehindAppBar: true,
          extendBody: true,
          backgroundColor: Colors.transparent,

          bottomNavigationBar:
              (Platform.isIOS || Platform.isAndroid)
                  ? Consumer<FileBadgeCount>(
                    builder: (context, count, child) {
                      return SafeArea(
                        child: Container(
                          padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
                          child: Container(
                            height: 90,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(30),
                                  spreadRadius: 0,
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                              color: context.color.primaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: BottomNavigationBar(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              selectedLabelStyle: TextStyle(
                                fontFamily: 'Jersey25',
                                fontSize: 18,
                              ),
                              unselectedLabelStyle: TextStyle(
                                fontFamily: 'Jersey25',
                                fontSize: 14,
                              ),
                              enableFeedback: false,
                              onTap: (index) {
                                setState(() {
                                  _currentTab = index;
                                });
                              },
                              currentIndex: _currentTab,
                              items: [
                                BottomNavigationBarItem(
                                  icon: HugeIcon(
                                    icon: HugeIcons.strokeRoundedQrCode,
                                    color: context.color.onSurface,
                                  ),
                                  activeIcon: HugeIcon(
                                    icon: HugeIcons.strokeRoundedQrCode,
                                    color: context.color.primary,
                                  ),
                                  label: context.l10n.send,
                                ),
                                BottomNavigationBarItem(
                                  icon: HugeIcon(
                                    icon: HugeIcons.strokeRoundedCamera02,
                                    color: context.color.onSurface,
                                  ),
                                  activeIcon: HugeIcon(
                                    icon: HugeIcons.strokeRoundedCamera02,
                                    color: context.color.primary,
                                  ),
                                  label: context.l10n.receive,
                                ),
                                BottomNavigationBarItem(
                                  icon: Badge(
                                    label: Text('${count.value ?? ''}'),
                                    isLabelVisible: count.value != null,
                                    child: HugeIcon(
                                      icon: HugeIcons.strokeRoundedFolder01,
                                      color: context.color.onSurface,
                                    ),
                                  ),
                                  activeIcon: HugeIcon(
                                    icon: HugeIcons.strokeRoundedFolder01,
                                    color: context.color.primary,
                                  ),
                                  label: context.l10n.my_files,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  )
                  : null,
          body: Builder(
            builder: (context) {
              switch (_currentTab) {
                case 0:
                  return SendPage();
                case 1:
                  return ScanPage();
                case 2:
                  return FilesPage();
              }
              return SizedBox();
            },
          ),
        ),
      ],
    );
  }
}
