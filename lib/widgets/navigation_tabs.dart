import 'package:blast_qr/color_scheme.dart';
import 'package:flutter/material.dart';

class NavigationTabs extends StatelessWidget {
  const NavigationTabs({
    super.key,
    this.onTap,
    required this.currentIndex,
    required this.items,
  });

  static const double height = 72;

  final void Function(int)? onTap;
  final int currentIndex;
  final List<BottomNavigationBarItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tabWidth = (constraints.maxWidth - 8) / items.length;
        return Stack(
          children: [
            Container(
              height: height,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(45),
                    spreadRadius: 0,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
                color: context.translucentSurface,
                borderRadius: BorderRadius.circular(36),
              ),
            ),
            AnimatedPositionedDirectional(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOutCubic,
              start: currentIndex * tabWidth,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 0, 0),
                child: Container(
                  height: 64,
                  width: tabWidth,
                  decoration: BoxDecoration(
                    color: context.color.primaryContainer,
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: height,
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(highlightColor: Colors.transparent),
                child: BottomNavigationBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  selectedLabelStyle: const TextStyle(
                    fontFamily: 'Jersey25',
                    fontSize: 16,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: 'Jersey25',
                    fontSize: 16,
                  ),
                  useLegacyColorScheme: false,
                  selectedIconTheme: IconThemeData(
                    color: context.color.primary,
                  ),
                  onTap: onTap,
                  currentIndex: currentIndex,
                  items: items,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
