import 'dart:math';

import 'package:blast_qr/color_scheme.dart';
import 'package:blast_qr/l10n/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ScanProgressWidget extends StatelessWidget {
  const ScanProgressWidget({
    super.key,
    required this.progress,
    required this.info,
    required this.onTapCancel,
    required this.chunkCount,
    required this.speed,
    required this.show,
  });

  final double progress;
  final String info;
  final int chunkCount;
  final String speed;
  final bool show;
  final void Function() onTapCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          child:
              Container(
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(36),
                      color: context.color.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(45),
                          spreadRadius: 0,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                      child: Row(
                        spacing: 8,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: CircularProgressIndicator(
                                  strokeCap: StrokeCap.round,
                                  value: progress > 1 ? null : progress,
                                  color: context.color.primary,
                                  backgroundColor: context.color.outline,
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: context.color.surface,
                                ),
                                width: 44,
                                height: 44,
                              ),
                              Text(
                                '${(progress.clamp(0, 1) * 100).floor()}%',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Jersey25',
                                  color: context.color.onSurface,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                progress > 1
                                    ? context.l10n.keep_scanning_msg
                                    : info,
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: 'Jersey25',
                                  color: context.color.onSurface,
                                  height: 1,
                                ),
                              ),
                              Text(
                                '$chunkCount | $speed',
                                style: TextStyle(
                                  color: context.color.onSurface,
                                ),
                                textAlign: TextAlign.end,
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: onTapCancel,
                            style: IconButton.styleFrom(
                              minimumSize: const Size(24, 24),
                              maximumSize: const Size(32, 32),
                              backgroundColor: context.color.primaryContainer,
                              foregroundColor: context.color.onSurface,
                            ),
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.clear, size: 16),
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate(target: show ? 1 : 0)
                  .fade()
                  .slideY(
                    begin: 0.75,
                    end: 0,
                    duration: 300.ms,
                    curve: Curves.easeOutBack,
                  ),
        ),
        // The bottom tabs overlap the page on phones; desktop has none.
        SizedBox(height: max(16, MediaQuery.of(context).padding.bottom - 64)),
      ],
    );
  }
}
