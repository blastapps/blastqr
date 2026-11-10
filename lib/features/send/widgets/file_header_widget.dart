import 'dart:ui' show ImageFilter;

import 'package:blast_qr/l10n/extension.dart';
import 'package:blast_qr/model/file_wrapper.dart';
import 'package:blast_qr/widgets/circle_button.dart';
import 'package:blast_qr/widgets/file_preview.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class FileHeaderWidget extends StatelessWidget {
  const FileHeaderWidget({
    super.key,
    required this.files,
    required this.onTapDismiss,
    this.compressedSize,
    this.encrypted = false,
    this.name,
  });

  /// The files picked to send. Several are sent as one bundle.
  final List<FileWrapper> files;
  final VoidCallback onTapDismiss;
  final int? compressedSize;

  final bool encrypted;

  final String? name;

  @override
  Widget build(BuildContext context) {
    final file = files.first;
    final size = files.fold(0, (sum, f) => sum + f.size);
    final sizeLabel = '${(size / 1000).toStringAsFixed(0)} KB';
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Stack(
        alignment: AlignmentDirectional.topEnd,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 12,
            children: [
              files.length > 1
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        StackedThumbnail(
                          files: files,
                          size: 56,
                          blurred: encrypted,
                        ),
                        if (encrypted) const _LockBadge(),
                      ],
                    )
                  : Container(
                      width: 56,
                      height: 56,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(60),
                            spreadRadius: 0,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: encrypted
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                ImageFiltered(
                                  imageFilter: ImageFilter.blur(
                                    sigmaX: 6,
                                    sigmaY: 6,
                                  ),
                                  child: file.buildThumbnail(context, size: 72),
                                ),
                                const Center(child: _LockBadge()),
                              ],
                            )
                          : file.buildThumbnail(context, size: 72),
                    ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 36),
                      child: Text(
                        files.length > 1
                            ? context.l10n.sending_files_count(files.length)
                            : name ?? file.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                    if (compressedSize != null && compressedSize != size)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 4,
                        children: [
                          Text(sizeLabel),
                          const Icon(Icons.arrow_forward, size: 14),
                          Text(
                            '${(compressedSize! / 1000).toStringAsFixed(0)} KB',
                          ),
                        ],
                      )
                    else
                      Text(sizeLabel),
                  ],
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
          SizedBox(
            height: 48,
            width: 48,
            child: CircleButton(
              icon: const Icon(Icons.clear),
              onPressed: onTapDismiss,
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            ),
          ),
        ],
      ),
    );
  }
}

class _LockBadge extends StatelessWidget {
  const _LockBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(110),
        shape: BoxShape.circle,
      ),
      child: const HugeIcon(
        icon: HugeIcons.strokeRoundedSquareLock02,
        size: 24,
        color: Colors.white,
      ),
    );
  }
}
