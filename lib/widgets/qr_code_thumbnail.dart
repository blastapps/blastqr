import 'package:blast_qr/qr_painter.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qr/qr.dart';

/// Renders [text] as a QR code on a white tile.
class QrCodeThumbnail extends StatefulWidget {
  const QrCodeThumbnail({super.key, required this.text, required this.size});

  final String text;
  final double size;

  @override
  State<QrCodeThumbnail> createState() => _QrCodeThumbnailState();
}

// Encoding is kept across rebuilds, like selection changes in a list.
class _QrCodeThumbnailState extends State<QrCodeThumbnail> {
  late QrImage? _image = _encode(widget.text);

  static QrImage? _encode(String text) {
    try {
      return QrImage(
        QrCode.fromData(data: text, errorCorrectLevel: QrErrorCorrectLevel.L),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void didUpdateWidget(QrCodeThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _image = _encode(widget.text);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final image = _image;
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
