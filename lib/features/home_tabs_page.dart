import 'dart:io';

import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/features/files_received/files_page.dart';
import 'package:blast_qr/features/scan/scan_page.dart';
import 'package:blast_qr/features/send/send_page.dart';
import 'package:blast_qr/features/send/qr_page.dart';
import 'package:blast_qr/file_badge_count.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blast_qr/nav_bar_visibility.dart';
import 'package:blast_qr/widgets/navigation_tabs.dart';
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
    final darkTheme = Theme.of(context).brightness == Brightness.dark;
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
                    opacity: darkTheme ? 0.6 : 0.25,
                    image: const AssetImage('assets/bg_qr.webp'),
                  ),
                ),
                height: 400,
              );
            }
            return Container(
              height: 400,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: const Alignment(0.5, 4),
                  colors: [context.color.surface, context.color.primary],
                ),
              ),
            );
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
                  ? Consumer2<FileBadgeCount, NavBarVisibility>(
                    builder: (context, count, navBar, child) {
                      return AnimatedSlide(
                        offset:
                            navBar.visible ? Offset.zero : const Offset(0, 1),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: AnimatedOpacity(
                          opacity: navBar.visible ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: SafeArea(
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                              child: NavigationTabs(
                                onTap: (index) {
                                  setState(() {
                                    _currentTab = index;
                                  });
                                },
                                currentIndex: _currentTab,
                                items: [
                                  BottomNavigationBarItem(
                                    icon: const HugeIcon(
                                      icon: HugeIcons.strokeRoundedSent02,
                                    ),
                                    label: context.l10n.send,
                                  ),
                                  BottomNavigationBarItem(
                                    icon: const HugeIcon(
                                      icon: HugeIcons.strokeRoundedQrCode,
                                    ),
                                    label: context.l10n.receive,
                                  ),
                                  BottomNavigationBarItem(
                                    icon: Badge(
                                      label: Text('${count.value ?? ''}'),
                                      isLabelVisible: count.value != null,
                                      child: const HugeIcon(
                                        icon: HugeIcons.strokeRoundedFolder01,
                                      ),
                                    ),
                                    label: context.l10n.my_files,
                                  ),
                                ],
                              ),
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
                  return const SendPage();
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
