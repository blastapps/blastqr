import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/crypto/password.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/widgets/blast_text_field.dart';
import 'package:blast_qr/widgets/bottom_sheets.dart';
import 'package:blast_qr/widgets/password_widgets.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

Future<String?> showCustomPasswordSheet(BuildContext context) {
  return showSheet<String>(
    context: context,
    title: context.l10n.custom_password_title,
    message: context.l10n.custom_password_msg,
    body: const Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: _CustomPasswordSheet(),
    ),
  );
}

class _CustomPasswordSheet extends StatefulWidget {
  const _CustomPasswordSheet();

  @override
  State<_CustomPasswordSheet> createState() => _CustomPasswordSheetState();
}

class _CustomPasswordSheetState extends State<_CustomPasswordSheet> {
  final _controller = TextEditingController(text: generatePassword());
  bool _editing = false;

  String get _password => _controller.text.trim();

  bool get _isShort =>
      !isGeneratedCode(_password) &&
      _password.length < minRecommendedPasswordLength;

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

  void _regenerate() {
    setState(() {
      _editing = false;
      _controller.text = generatePassword();
    });
  }

  void _edit() {
    setState(() {
      _editing = true;
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  void _sendEncrypted() {
    if (_password.isEmpty) return;
    Navigator.of(context).pop<String>(formatPassword(_password));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Row(
          spacing: 4,
          children: [
            Expanded(
              child:
                  _editing
                      ? BlastTextField(
                        controller: _controller,
                        hintText: context.l10n.password,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        style: passwordTextStyle(context, fontSize: 24),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _sendEncrypted(),
                      )
                      : Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: context.color.surfaceContainer,
                          border: Border.all(color: context.color.outline),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _password,
                            maxLines: 1,
                            style: passwordTextStyle(context, fontSize: 28),
                          ),
                        ),
                      ),
            ),

            if (!_editing)
              IconButton(
                onPressed: _edit,
                tooltip: context.l10n.edit_password,
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedPencilEdit01,
                  color: context.color.onSurface,
                ),
              ),
            IconButton(
              onPressed: _regenerate,
              tooltip: context.l10n.new_password,
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedRefresh,
                color: context.color.onSurface,
              ),
            ),
          ],
        ),
        if (_isShort && _password.isNotEmpty)
          Text(
            context.l10n.password_short_warning,
            style: TextStyle(color: context.color.error),
          ),

        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _password.isEmpty ? null : _sendEncrypted,
          child: Text(context.l10n.send_encrypted),
        ),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
      ],
    );
  }
}
