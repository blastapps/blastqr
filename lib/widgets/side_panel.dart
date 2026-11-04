import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/widgets/logo_widget.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Desktop side panel with the logo, the tabs and the settings button.
/// It is as wide as its widest item, usually the logo.
class SidePanel extends StatelessWidget {
  const SidePanel({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTabTap,
    required this.onSettingsTap,
  });

  static const double _tabHeight = 48;

  final List<BottomNavigationBarItem> items;
  final int currentIndex;
  final void Function(int) onTabTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.translucentSurface,
        border: BorderDirectional(
          end: BorderSide(color: context.color.outline),
        ),
      ),
      // Hover highlights paint on the nearest Material, which would otherwise
      // be below the panel's background.
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Center(child: LogoWidget()),
                ),
                const SizedBox(height: 32),
                if (items.isNotEmpty) _tabs(context),
                const Spacer(),
                _SidePanelTile(
                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedSettings01),
                  label: context.l10n.settings,
                  selected: false,
                  onTap: onSettingsTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabs(BuildContext context) {
    return Stack(
      children: [
        AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOutCubic,
          top: currentIndex * _tabHeight,
          left: 0,
          right: 0,
          height: _tabHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.color.primaryContainer,
              borderRadius: BorderRadius.circular(_tabHeight / 2),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, item) in items.indexed)
              _SidePanelTile(
                icon: item.icon,
                label: item.label ?? '',
                selected: index == currentIndex,
                onTap: () => onTabTap(index),
              ),
          ],
        ),
      ],
    );
  }
}

class _SidePanelTile extends StatelessWidget {
  const _SidePanelTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? context.color.primary : context.color.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SidePanel._tabHeight / 2),
      highlightColor: Colors.transparent,
      child: SizedBox(
        height: SidePanel._tabHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            spacing: 12,
            children: [
              IconTheme(
                data: IconThemeData(color: color, size: 22),
                child: icon,
              ),
              Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'Jersey25',
                  fontSize: 20,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
