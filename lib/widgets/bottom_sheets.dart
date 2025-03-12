import 'package:blast_qr/widgets/is_text_field.dart';
import 'package:flutter/material.dart';

class TextInputSheet extends StatelessWidget {
  const TextInputSheet({
    super.key,
    required this.title,
    required this.inputHintText,
    required this.confirmText,
    required this.onConfirm,
    required this.controller,
  });

  final String title;
  final String inputHintText;
  final String confirmText;
  final void Function(String text) onConfirm;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ISTextField(
          hintText: inputHintText,
          controller: controller,
          autofocus: true,
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
  String prefilledText = "",
  String? confirmText,
  TextSelection? selection,
  required hintText,
  required void Function(String text) onConfirm,
}) {
  final controller = TextEditingController(text: prefilledText);
  controller.selection =
      selection ?? TextSelection(baseOffset: 0, extentOffset: 0);
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
        onConfirm: onConfirm,
      ),
    ),
  );
}
