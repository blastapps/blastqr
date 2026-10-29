import 'package:blast_qr/qr_painter.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qr/qr.dart';

/// Renders [text] as a QR code on a white tile.
class QrCodeThumbnail extends StatelessWidget {
  const QrCodeThumbnail({super.key, required this.text, required this.size});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    QrImage? image;
    try {
      image = QrImage(
        QrCode.fromData(data: text, errorCorrectLevel: QrErrorCorrectLevel.L),
      );
    } catch (_) {}
    return Container(
      width: size,
      height: size,
      color: Colors.white,
      padding: EdgeInsets.all(size * 0.08),
      child: image == null
          ? const HugeIcon(
              icon: HugeIcons.strokeRoundedQrCode,
              color: Colors.black,
            )
          : CustomPaint(painter: QrPainter.withQr(qrImage: image)),
    );
  }
}
