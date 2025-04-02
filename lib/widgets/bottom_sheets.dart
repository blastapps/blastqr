import 'package:blast_qr/widgets/blast_text_field.dart';
import 'package:flutter/material.dart';

class TextInputSheet extends StatelessWidget {
  const TextInputSheet({
    super.key,
    required this.title,
    required this.inputHintText,
    required this.confirmText,
    required this.onConfirm,
    required this.controller,
    this.keyboardType,
  });

  final String title;
  final String inputHintText;
  final String confirmText;
  final void Function(String text) onConfirm;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlastTextField(
          hintText: inputHintText,
          controller: controller,
          autofocus: true,
          keyboardType: keyboardType,
          onSubmitted: (val) {
            _confirm(context);
          },
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            _confirm(context);
          },
          child: Text(confirmText),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _confirm(BuildContext context) {
    Navigator.of(context).pop();
    onConfirm(controller.text);
  }
}

class PickerSheet extends StatelessWidget {
  const PickerSheet({
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
    body: Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
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
              child: Text(confirmTitle),
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
              child: Text(secondaryTitle),
            ),
        ],
      ),
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
    backgroundColor:
        backgroundColor ?? Theme.of(context).colorScheme.primaryContainer,
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
          0,
          0,
          0,
          MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).viewPadding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            const SizedBox(height: 24),
            body,
          ],
        ),
      );
    },
  );
}

Future<void> showTextInputSheet(
  BuildContext context, {
  required title,
  String prefilledText = '',
  String? confirmText,
  TextSelection? selection,
  TextInputType? keyboardType,
  required hintText,
  required void Function(String text) onConfirm,
}) {
  final controller = TextEditingController(text: prefilledText);
  controller.selection =
      selection ??
      TextSelection(baseOffset: 0, extentOffset: prefilledText.length);
  return showSheet(
    context: context,
    title: title,
    body: Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: TextInputSheet(
        title: title,
        controller: controller,
        inputHintText: hintText,
        confirmText: confirmText ?? 'Save',
        keyboardType: keyboardType,
        onConfirm: onConfirm,
      ),
    ),
  );
}

Future<void> showPickerSheet(
  BuildContext context, {
  required title,
  required List<String> items,
  List<Widget>? icons,
  double? itemHeight = 56,
  required void Function(int index) onItemTap,
}) {
  return showSheet(
    context: context,
    title: title,
    body: PickerSheet(
      items: items,
      onItemTap: onItemTap,
      icons: icons,
      itemHeight: itemHeight,
    ),
  );
}
