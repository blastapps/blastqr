import 'dart:io';

import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/features/files_received/files_page.dart';
import 'package:blast_qr/features/scan/scan_page.dart';
import 'package:blast_qr/features/send/qr_page.dart';
import 'package:blast_qr/features/send/send_options.dart';
import 'package:blast_qr/features/send/send_page.dart';
import 'package:blast_qr/file_badge_count.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/file_extension.dart';
import 'package:blast_qr/nav_bar_visibility.dart';
import 'package:blast_qr/platform_support.dart';
import 'package:blast_qr/widgets/navigation_tabs.dart';
import 'package:blast_qr/widgets/qr_twinkle_background.dart';
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
  static const _scanTab = 1;

  int _currentTab = 0;
  SharedMedia? media;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    if (Platform.isMacOS) return;
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
            // Not on the camera tab: the shader would keep the GPU busy
            // while the camera is scanning.
            if (state.animations && _currentTab != _scanTab) {
              return SizedBox.expand(
                child: QrTwinkleBackground(
                  color: context.color.primary,
                  opacity: darkTheme ? 0.26 : 0.12,
                  // Fade in from below the status bar, so only a faint bit
                  // shows behind the pages' (transparent, 80 high) app bars.
                  fadeStart: MediaQuery.paddingOf(context).top,
                  fadeLength: 240,
                ),
              );
            }
            return Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  height: 400,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: const Alignment(0.5, 4),
                      colors: [context.color.surface, context.color.primary],
                    ),
                  ),
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
              ],
            );
          },
        ),
        Scaffold(
          extendBodyBehindAppBar: true,
          extendBody: true,
          backgroundColor: Colors.transparent,
          bottomNavigationBar:
              canScanWithCamera
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
          body: Stack(
            children: [
              Offstage(offstage: _currentTab != 0, child: const SendPage()),
              if (_currentTab == _scanTab) const ScanPage(),
              if (_currentTab == 2) const FilesPage(),
            ],
          ),
        ),
      ],
    );
  }

  void _showQrPage(File file) async {
    Navigator.of(context).popUntil((r) => r.isFirst); // Go back to main screen
    final fileWrapper = await file.toFileWrapper();
    if (!mounted) return;
    final options = await chooseSendOptions(context, [fileWrapper]);
    if (options == null || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) {
          return QrPage(
            file: fileWrapper,
            password: options.password,
            fileName: options.fileName,
          );
        },
      ),
    );
  }
}
