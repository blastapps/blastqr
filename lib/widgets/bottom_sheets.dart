import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/widgets/blast_text_field.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

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
    this.selectedItemIndex,
  });

  final List<String> items;
  final List<Widget>? icons;
  final double? itemHeight;
  final int? selectedItemIndex;
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
              trailing:
                  selectedItemIndex == index
                      ? HugeIcon(
                        icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                        color: context.color.primary,
                      )
                      : null,
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

class SliderSheet extends StatefulWidget {
  const SliderSheet({
    super.key,
    required this.title,
    required this.confirmText,
    required this.onConfirm,
    required this.min,
    required this.max,
    required this.value,
    required this.defaultValue,
  });

  final String title;
  final String confirmText;
  final void Function(int val) onConfirm;
  final int min;
  final int max;
  final int value;
  final int defaultValue;

  @override
  State<SliderSheet> createState() => SliderSheetState();
}

class SliderSheetState extends State<SliderSheet> {
  int _value = 0;
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
    _textController = TextEditingController(text: widget.value.toString());
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    final parsed = int.tryParse(text);
    if (parsed == null) return;
    final clamped = parsed.clamp(widget.min, widget.max);
    setState(() {
      _value = clamped;
    });
  }

  void reset() {
    setState(() {
      _value = widget.defaultValue;
      _textController.text = widget.defaultValue.toString();
      _textController.selection = TextSelection.collapsed(
        offset: _textController.text.length,
      );
    });
  }

  void _onSliderChanged(double val) {
    final intVal = val.toInt();
    setState(() {
      _value = intVal;
      _textController.text = intVal.toString();
      _textController.selection = TextSelection.collapsed(
        offset: _textController.text.length,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: BlastTextField(
            controller: _textController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onSubmitted: _onTextChanged,
            textAlign: TextAlign.center,
            autofocus: false,
            style: const TextStyle(fontFamily: 'Jersey25', fontSize: 32),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Slider(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
            min: widget.min.toDouble(),
            max: widget.max.toDouble(),
            value: _value.toDouble(),
            onChanged: _onSliderChanged,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            _onTextChanged(_textController.text);
            _confirm(context);
          },
          child: Text(widget.confirmText),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _confirm(BuildContext context) {
    Navigator.of(context).pop();
    widget.onConfirm(_value);
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
          Text(message, style: const TextStyle(fontSize: 16)),
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

Future<T?> showSheet<T>({
  required BuildContext context,
  required String title,
  String? message,
  required Widget body,
  Color? backgroundColor,
  Widget? titleTrailing,
  double messageBottomPadding = 24,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<T>(
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  if (titleTrailing != null) titleTrailing,
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (message?.isNotEmpty == true)
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, messageBottomPadding),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: context.color.surfaceContainer,
                    border: Border.all(color: context.color.outline),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 12,
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedInformationCircle,
                      ),
                      Expanded(child: Text(message!)),
                    ],
                  ),
                ),
              ),
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
        confirmText: confirmText ?? context.l10n.save,
        keyboardType: keyboardType,
        onConfirm: onConfirm,
      ),
    ),
  );
}

Future<void> showPickerSheet(
  BuildContext context, {
  required title,
  String? message,
  required List<String> items,
  List<Widget>? icons,
  double? itemHeight = 56,
  int? selectedItemIndex,
  required void Function(int index) onItemTap,
}) {
  return showSheet(
    context: context,
    title: title,
    message: message,
    messageBottomPadding: 0,
    body: PickerSheet(
      items: items,
      onItemTap: onItemTap,
      icons: icons,
      itemHeight: itemHeight,
      selectedItemIndex: selectedItemIndex,
    ),
  );
}

Future<void> showSliderSheet(
  BuildContext context, {
  required String title,
  String? confirmText,
  String? message,
  required int value,
  required int min,
  required int max,
  required int defaultValue,
  required void Function(int val) onConfirm,
}) {
  final sliderKey = GlobalKey<SliderSheetState>();
  return showSheet(
    context: context,
    title: title,
    message: message,
    titleTrailing: IconButton(
      onPressed: () => sliderKey.currentState?.reset(),
      icon: const HugeIcon(icon: HugeIcons.strokeRoundedUndo),
    ),
    body: Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: SliderSheet(
        key: sliderKey,
        title: title,
        confirmText: confirmText ?? context.l10n.save,
        onConfirm: onConfirm,
        value: value,
        min: min,
        max: max,
        defaultValue: defaultValue,
      ),
    ),
  );
}
