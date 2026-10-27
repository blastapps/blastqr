import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/crypto/password.dart';
import 'package:blast_qr/features/send/widgets/custom_password_sheet.dart';
import 'package:blast_qr/file_name_utils.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blast_qr/widgets/bottom_sheets.dart';
import 'package:blast_qr/widgets/file_preview.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

typedef SendOptions = ({String? password, String? fileName});

const SendOptions plainSend = (password: null, fileName: null);

SendOptions encryptedSend({String? fileName}) =>
    (password: generatePassword(), fileName: fileName);

/// Returns null if the user cancelled the send.
Future<SendOptions?> chooseSendOptions(
  BuildContext context,
  List<FileWrapper> files,
) async {
  final result = await showSheet<_SendSheetResult>(
    context: context,
    title: context.l10n.send,
    body: _SendSheet(files: files),
  );
  if (result == null) return null;
  if (!result.customPassword) return result.options;

  if (!context.mounted) return null;
  final password = await showCustomPasswordSheet(context);
  if (password == null) return null;
  return (password: password, fileName: result.options.fileName);
}

typedef _SendSheetResult = ({SendOptions options, bool customPassword});

class _SendSheet extends StatefulWidget {
  const _SendSheet({required this.files});

  final List<FileWrapper> files;

  @override
  State<_SendSheet> createState() => _SendSheetState();
}

class _SendSheetState extends State<_SendSheet> {
  late final _nameController = TextEditingController(
    text: widget.files.first.name,
  );

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String? get _fileName {
    if (widget.files.length != 1) return null;
    final original = widget.files.first.name;
    final typed = _nameController.text.trim();
    if (typed.isEmpty || typed == original) return null;
    return sanitizeFileName(typed);
  }

  void _close(SendOptions options, {bool customPassword = false}) {
    Navigator.of(
      context,
    ).pop<_SendSheetResult>((options: options, customPassword: customPassword));
  }

  @override
  Widget build(BuildContext context) {
    final file = widget.files.first;
    return Column(
      children: [
        if (widget.files.length == 1) ...[
          FileThumbnail(file: file, size: 92),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _nameController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                suffixIcon: Padding(
                  padding: const EdgeInsetsGeometry.all(12),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedEdit01,
                    color: context.color.onSurface,
                  ),
                ),
                contentPadding: const EdgeInsets.fromLTRB(48, 0, 0, 8),
              ),
              onTap: () {
                final dotIndex = _nameController.text.lastIndexOf('.');
                _nameController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: dotIndex > 0
                      ? dotIndex
                      : _nameController.text.length,
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Text(
            file.sizeInkB,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.color.secondary),
          ),
        ] else
          FilesPreview(files: widget.files),
        const SizedBox(height: 8),
        SendTile(onTap: () => _close((password: null, fileName: _fileName))),
        SendEncryptedTile(
          onTap: () => _close(encryptedSend(fileName: _fileName)),
          onLongPress: () => _close((
            password: null,
            fileName: _fileName,
          ), customPassword: true),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class SendTile extends StatelessWidget {
  const SendTile({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      onTap: onTap,
      leading: HugeIcon(
        icon: HugeIcons.strokeRoundedSent02,
        color: context.color.primary,
      ),
      title: Text(context.l10n.send),
    );
  }
}

class SendEncryptedTile extends StatelessWidget {
  const SendEncryptedTile({super.key, required this.onTap, this.onLongPress});

  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      onTap: onTap,
      onLongPress: onLongPress,
      leading: HugeIcon(
        icon: HugeIcons.strokeRoundedSquareLock02,
        color: context.color.primary,
      ),
      title: Text(context.l10n.send_encrypted),
    );
  }
}
