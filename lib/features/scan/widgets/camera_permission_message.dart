import 'package:blast_qr/l10n/extension.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class CameraPermissionMessage extends StatelessWidget {
  const CameraPermissionMessage({super.key, required this.onEnable});

  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedCameraOff02,
                color: Colors.white,
                size: 48,
              ),
              Text(
                context.l10n.camera_permission_msg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              ElevatedButton(
                onPressed: onEnable,
                child: Text(context.l10n.enable_camera),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
