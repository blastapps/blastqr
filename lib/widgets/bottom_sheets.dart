import 'package:flutter/material.dart';

class ISPickerSheet extends StatelessWidget {
  const ISPickerSheet({
    super.key,
    required this.items,
    this.onItemTap,
    this.icons,
    this.itemHeight,
  });

  final List<String> items;
  final List<Widget>? icons;
  final double? itemHeight;
  final void Function(int index)? onItemTap;

  double? get _height => itemHeight != null ? itemHeight! * items.length : null;

  ScrollPhysics? get scrollPhysics {
    if (itemHeight != null && items.length < 7) {
      return const NeverScrollableScrollPhysics();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height ?? MediaQuery.of(context).size.height / 2,
      child: Scrollbar(
        child: ListView.builder(
          physics: scrollPhysics,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item),
              leading: icons?.elementAtOrNull(index),
              onTap: () {
                Navigator.of(context).pop();
                onItemTap?.call(index);
              },
            );
          },
        ),
      ),
    );
  }
}

Future<void> showMessage({
  required BuildContext context,
  required String title,
  required String message,
  Icon? icon,
  Color? backgroundColor,
  String? confirmTitle = 'OK',
  String? secondaryTitle,
  ButtonStyle? confirmButtonStyle,
  ButtonStyle? secondaryButtonStyle,
  void Function()? onConfirmTap,
  void Function()? onSecondaryTap,
}) {
  return showSheet(
    context: context,
    title: title,
    backgroundColor: backgroundColor,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message),
        const SizedBox(height: 16),
        if (confirmTitle != null)
          ElevatedButton(
            onPressed: () {
              onConfirmTap?.call();
              Navigator.of(context).pop();
            },
            style: confirmButtonStyle,
            child: Text(confirmTitle.toUpperCase()),
          ),
        const SizedBox(height: 8),
        if (secondaryTitle != null)
          OutlinedButton(
            onPressed:
                onSecondaryTap ??
                () {
                  Navigator.of(context).pop();
                },
            style: secondaryButtonStyle,
            child: Text(secondaryTitle.toUpperCase()),
          ),
      ],
    ),
  );
}

Future<void> showSheet({
  required BuildContext context,
  required String title,
  required Widget body,
  Color? backgroundColor,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surface,
    enableDrag: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(24),
        bottom: Radius.zero,
      ),
    ),
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).viewPadding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            body,
          ],
        ),
      );
    },
  );
}

Future<void> showPickerWidget(
  BuildContext context, {
  required title,
  required List<String> items,
  List<Widget>? icons,
  double? itemHeight,
  required void Function(int index) onItemTap,
}) {
  return showSheet(
    context: context,
    title: title,
    body: ISPickerSheet(
      items: items,
      onItemTap: onItemTap,
      icons: icons,
      itemHeight: itemHeight,
    ),
  );
}
