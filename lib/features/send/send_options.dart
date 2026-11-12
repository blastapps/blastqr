import 'package:blast_qr/app_settings.dart';
import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/crypto/password.dart';
import 'package:blast_qr/features/send/prepare_transfer.dart';
import 'package:blast_qr/features/send/send_files.dart';
import 'package:blast_qr/features/send/widgets/custom_password_sheet.dart';
import 'package:blast_qr/features/send/widgets/hd_toggle.dart';
import 'package:blast_qr/features/send/widgets/send_estimate.dart';
import 'package:blast_qr/file_name_utils.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blast_qr/widgets/bottom_sheets.dart';
import 'package:blast_qr/widgets/centered_with_trailing.dart';
import 'package:blast_qr/widgets/file_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

typedef SendOptions = ({
  String? password,
  String? fileName,
  bool compressMedia,
});

SendOptions plainSend({required bool compressMedia}) =>
    (password: null, fileName: null, compressMedia: compressMedia);

SendOptions encryptedSend({String? fileName, required bool compressMedia}) => (
  password: generatePassword(),
  fileName: fileName,
  compressMedia: compressMedia,
);

typedef ChosenSend = ({List<FileWrapper> files, SendOptions options});

/// Shows the send sheet right away, with "Preparing transfer..." until [files]
/// arrive, e.g. while a picker copies them. The sheet closes if there are
/// none, and tells the user if they're too large to send. Returns null if
/// nothing is to be sent.
Future<ChosenSend?> chooseFilesAndSendOptions(
  BuildContext context,
  Future<List<FileWrapper>> files,
) async {
  final result = await showSheet<_SheetResult>(
    context: context,
    title: context.l10n.send_files_title,
    body: _SendSheet(files: files),
  );
  if (!context.mounted) return null;
  switch (result) {
    case null:
      return null;
    case _TooLarge(:final message):
      await showFileTooLarge(context, message);
      return null;
    case _Chosen(:final files, :final options, customPassword: false):
      return (files: files, options: options);
    case _Chosen(:final files, :final options):
      final password = await showCustomPasswordSheet(context);
      if (password == null) return null;
      return (
        files: files,
        options: (
          password: password,
          fileName: options.fileName,
          compressMedia: options.compressMedia,
        ),
      );
  }
}

/// Returns null if the user cancelled the send.
Future<SendOptions?> chooseSendOptions(
  BuildContext context,
  List<FileWrapper> files,
) async => (await chooseFilesAndSendOptions(
  context,
  SynchronousFuture(files),
))?.options;

sealed class _SheetResult {}

final class _Chosen implements _SheetResult {
  const _Chosen(this.files, this.options, {required this.customPassword});

  final List<FileWrapper> files;
  final SendOptions options;
  final bool customPassword;
}

final class _TooLarge implements _SheetResult {
  const _TooLarge(this.message);

  final String message;
}

class _SendSheet extends StatefulWidget {
  const _SendSheet({required this.files});

  final Future<List<FileWrapper>> files;

  @override
  State<_SendSheet> createState() => _SendSheetState();
}

class _SendSheetState extends State<_SendSheet> {
  List<FileWrapper>? _files;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    widget.files.then(
      (files) {
        if (mounted) setState(() => _files = files);
      },
      onError: (Object error) {
        debugPrint('Preparing files failed: $error');
        if (mounted) _close(null);
      },
    );
  }

  /// Closes after this frame, as it can happen while building. If the user
  /// already swiped the sheet away, popping would close the page below it.
  void _close(_SheetResult? result) {
    if (_closing) return;
    _closing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
        Navigator.of(context).pop(result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final files = _files;
    if (files != null && !_closing) {
      final tooLarge = files.isEmpty
          ? null
          : transferTooLargeMessage(context, minSendBytes(files));
      if (files.isEmpty || tooLarge != null) {
        _close(tooLarge == null ? null : _TooLarge(tooLarge));
      } else {
        return SendOptionsBody(
          files: files,
          onChosen: (options, {customPassword = false}) =>
              _close(_Chosen(files, options, customPassword: customPassword)),
        );
      }
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            const CircularProgressIndicator.adaptive(),
            Text(context.l10n.preparing_transfer, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// The file preview, name and HD toggle, and the ways to send.
class SendOptionsBody extends StatefulWidget {
  const SendOptionsBody({
    super.key,
    required this.files,
    required this.onChosen,
  });

  final List<FileWrapper> files;
  final void Function(SendOptions options, {bool customPassword}) onChosen;

  @override
  State<SendOptionsBody> createState() => _SendOptionsBodyState();
}

class _SendOptionsBodyState extends State<SendOptionsBody> {
  late final _nameController = TextEditingController(
    text: widget.files.first.name,
  );
  late final _hd = ValueNotifier(
    !Provider.of<AppSettings>(context, listen: false).compressMediaByDefault,
  );
  late final _showsHd = widget.files.any(isCompressibleMedia);

  @override
  void dispose() {
    _nameController.dispose();
    _hd.dispose();
    super.dispose();
  }

  String? get _fileName {
    if (widget.files.length != 1) return null;
    final original = widget.files.first.name;
    final typed = _nameController.text.trim();
    if (typed.isEmpty || typed == original) return null;
    return sanitizeFileName(typed);
  }

  void _close(SendOptions options, {bool customPassword = false}) =>
      widget.onChosen(options, customPassword: customPassword);

  @override
  Widget build(BuildContext context) {
    final file = widget.files.first;
    return Column(
      children: [
        if (widget.files.length == 1) ...[
          CenteredWithTrailing(
            trailing: _showsHd ? HdToggle(hd: _hd) : null,
            child: FileThumbnail(file: file, size: 92),
          ),
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
                contentPadding: const EdgeInsetsDirectional.fromSTEB(
                  48,
                  0,
                  0,
                  8,
                ),
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
          SendEstimate(files: widget.files, hd: _hd),
        ] else ...[
          CenteredWithTrailing(
            trailing: _showsHd ? HdToggle(hd: _hd) : null,
            child: FilesPreview(
              files: widget.files,
              maxShown: _showsHd ? 3 : 4,
            ),
          ),
          const SizedBox(height: 4),
          SendEstimate(files: widget.files, hd: _hd),
        ],
        const SizedBox(height: 8),
        SendTile(
          onTap: () => _close((
            password: null,
            fileName: _fileName,
            compressMedia: !_hd.value,
          )),
        ),
        SendEncryptedTile(
          onTap: () => _close(
            encryptedSend(fileName: _fileName, compressMedia: !_hd.value),
          ),
          onLongPress: () => _close((
            password: null,
            fileName: _fileName,
            compressMedia: !_hd.value,
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
