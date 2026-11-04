import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/widgets/file_list_selection.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

/// What the selection bar shows. The page that is selecting files fills it
/// in, and the home page shows it: in place of the tabs on phones, at the
/// bottom on desktop.
class SelectionBarController extends ChangeNotifier {
  Object? _owner;
  bool _disposed = false;
  int _count = 0;
  VoidCallback? _onClear;
  VoidCallback? _onOpen;

  bool get isShowing => _owner != null;
  int get count => _count;

  void show(
    Object owner, {
    required int count,
    required VoidCallback onClear,
    required VoidCallback onOpen,
  }) {
    _owner = owner;
    _count = count;
    _onClear = onClear;
    _onOpen = onOpen;
    notifyListeners();
  }

  void hide(Object owner) {
    if (_owner != owner || _disposed) return;
    _owner = null;
    _onClear = null;
    _onOpen = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Asks the selecting page to clear its selection, which hides the bar.
  void clear() => _onClear?.call();

  void open() => _onOpen?.call();
}

/// For a page with a [FileListSelection]: keeps the selection bar showing
/// while files are selected.
mixin SelectionBarOwner<T extends StatefulWidget> on State<T> {
  late final SelectionBarController _selectionBar;
  bool _showsSelectionBar = false;

  bool get showsSelectionBar => _showsSelectionBar;

  @override
  void initState() {
    super.initState();
    _selectionBar = context.read<SelectionBarController>();
  }

  /// Call when [selection] changes. [onOpen] is the bar's arrow.
  void updateSelectionBar(
    FileListSelection<Object?> selection, {
    required VoidCallback onOpen,
  }) {
    _showsSelectionBar = selection.isNotEmpty;
    if (_showsSelectionBar) {
      _selectionBar.show(
        this,
        count: selection.length,
        onClear: selection.clear,
        onOpen: onOpen,
      );
    } else {
      _selectionBar.hide(this);
    }
  }

  @override
  void dispose() {
    // The home page can't rebuild while this page is being removed.
    final bar = _selectionBar;
    if (bar._owner == this) {
      WidgetsBinding.instance.addPostFrameCallback((_) => bar.hide(this));
    }
    super.dispose();
  }
}

/// The selection count with clear and open buttons, shown where the phone
/// tabs are.
class SelectionBar extends StatelessWidget {
  const SelectionBar({super.key, required this.controller});

  static const height = 56.0;

  final SelectionBarController controller;

  @override
  Widget build(BuildContext context) {
    final color = context.color.onPrimary;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Material(
        color: context.color.primary,
        elevation: 3,
        shadowColor: Colors.black.withAlpha(120),
        shape: StadiumBorder(
          side: BorderSide(color: context.color.surface, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: controller.open,
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: context.l10n.cancel,
                    onPressed: controller.clear,
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      color: color,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${controller.count} ${context.l10n.selected}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Jersey25',
                        fontSize: 20,
                        color: color,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: controller.open,
                    icon: HugeIcon(
                      icon: context.isRtl
                          ? HugeIcons.strokeRoundedArrowLeft01
                          : HugeIcons.strokeRoundedArrowRight01,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
