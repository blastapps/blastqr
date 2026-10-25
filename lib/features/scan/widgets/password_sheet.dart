import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/widgets/blast_text_field.dart';
import 'package:blast_qr/widgets/bottom_sheets.dart';
import 'package:blast_qr/widgets/password_widgets.dart';
import 'package:flutter/material.dart';

Future<String?> showPasswordSheet(
  BuildContext context, {
  String initialText = '',
  bool wrongPassword = false,
}) {
  return showSheet<String>(
    context: context,
    title: context.l10n.enter_password,
    message: context.l10n.enter_password_msg,
    body: Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: _PasswordSheet(
        initialText: initialText,
        wrongPassword: wrongPassword,
      ),
    ),
  );
}

class _PasswordSheet extends StatefulWidget {
  const _PasswordSheet({required this.initialText, required this.wrongPassword});

  final String initialText;
  final bool wrongPassword;

  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<_PasswordSheet> {
  late final _controller = TextEditingController(text: widget.initialText)
    ..selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.initialText.length,
    );

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        BlastTextField(
          controller: _controller,
          hintText: 'XXXX-XXXX-XXXX',
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.done,
          textAlign: TextAlign.center,
          style: passwordTextStyle(context, fontSize: 16),
          onSubmitted: (_) => _submit(),
        ),
        if (widget.wrongPassword)
          Text(
            context.l10n.wrong_password,
            style: TextStyle(color: context.color.error),
          ),
        ElevatedButton(
          onPressed: _controller.text.trim().isEmpty ? null : _submit,
          child: Text(context.l10n.unlock),
        ),
      ],
    );
  }
}
