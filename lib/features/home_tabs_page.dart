import 'dart:io';

import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/features/files_received/files_page.dart';
import 'package:blast_qr/features/scan/scan_page.dart';
import 'package:blast_qr/features/send/file_picker_page.dart';
import 'package:blast_qr/features/send/qr_page.dart';
import 'package:blast_qr/file_badge_count.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:share_handler/share_handler.dart';

class HomeTabsPage extends StatefulWidget {
  const HomeTabsPage({super.key});

  @override
  State<HomeTabsPage> createState() => _HomeTabsPageState();
}

class _HomeTabsPageState extends State<HomeTabsPage> {
  int _currentTab = 0;
  SharedMedia? media;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    final handler = ShareHandlerPlatform.instance;
    media = await handler.getInitialSharedMedia();

    handler.sharedMediaStream.listen((SharedMedia media) {
      if (!mounted) return;
      final path = media.attachments?.first?.path;
      if (path != null) {
        _showQrPage(File(path));
      }
    });
    if (!mounted) return;

    final path = media?.attachments?.first?.path;
    if (path != null) {
      _showQrPage(File(path));
    }

    handler.resetInitialSharedMedia();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(color: context.color.surface),
        Consumer<AppSettings>(
          builder: (context, state, child) {
            if (state.animations) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  image: DecorationImage(
                    colorFilter: ColorFilter.mode(
                      context.color.primary,
                      BlendMode.srcATop,
                    ),
                    fit: BoxFit.cover,
                    opacity:
                        Theme.of(context).brightness == Brightness.dark
                            ? 0.6
                            : 0.25,
                    image: const AssetImage('assets/bg_qr.webp'),
                  ),
                ),
                height: 400,
              );
            }
            return const SizedBox();
          },
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: const FractionalOffset(0.5, 0.0),
              end: const FractionalOffset(0.5, 1.5),
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
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                          child: Container(
                            height: 90,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(30),
                                  spreadRadius: 0,
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                              color: context.color.primaryContainer.withAlpha(
                                215,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: BottomNavigationBar(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              selectedLabelStyle: const TextStyle(
                                fontFamily: 'Jersey25',
                                fontSize: 18,
                              ),
                              unselectedLabelStyle: const TextStyle(
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
                  return const FilePickerPage();
                case 1:
                  return const ScanPage();
                case 2:
                  return const FilesPage();
              }
              return const SizedBox();
            },
          ),
        ),
      ],
    );
  }

  void _showQrPage(File file) async {
    Navigator.of(context).popUntil((r) => r.isFirst); // Go back to main screen
    final fileWrapper = await file.toFileWrapper();
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) {
            return QrPage(file: fileWrapper);
          },
        ),
      );
    }
  }
}
