import 'dart:math';

import 'package:blast_qr/my_qr_painter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCodePageOptimized extends StatefulWidget {
  const QrCodePageOptimized({super.key});

  @override
  State<QrCodePageOptimized> createState() => _QrCodePageOptimizedState();
}

class _QrCodePageOptimizedState extends State<QrCodePageOptimized>
    with SingleTickerProviderStateMixin {
  int index = 0;
  late Ticker _ticker;
  Duration _lastUpdate = Duration.zero;
  Duration frameInterval = const Duration(microseconds: 33333); //30fps

  List<QrCode> _qrCodes = [];
  List<QrImage> _qrImages = [];

  @override
  void initState() {
    super.initState();
    _generateImages().then((result) {
      debugPrint('Finished processing images');
      if (!mounted) {
        return;
      }
      setState(() {
        _qrCodes = result[0];
        _qrImages = result[1];
      });

      _ticker.start();
    });

    _ticker = createTicker((elapsed) {
      if (elapsed - _lastUpdate >= frameInterval) {
        _lastUpdate = elapsed;
        setState(() {
          if (index < _qrCodes.length - 1) {
            index++;
          } else {
            index = 0;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  static Future<List<dynamic>> _generateImages() async {
    return compute(_qrCodesToImages, 50);
  }

  static List<dynamic> _qrCodesToImages(int chunkCount) {
    final stopwatch = Stopwatch()..start();
    int numberOfLists = chunkCount; // Number of Uint8Lists
    int chunkLen = 1333; // Number of bytes per Uint8List

    List<Uint8List> randomLists = List.generate(
      numberOfLists,
      (_) => _generateRandomUint8List(chunkLen),
    );
    debugPrint(
      'Random list processed at ${stopwatch.elapsed.inMilliseconds}ms',
    );

    final codes =
        randomLists
            .map(
              (data) => QrCode.fromUint8List(
                data: data,
                errorCorrectLevel: QrErrorCorrectLevel.L,
              ),
            )
            .toList();
    debugPrint('Codes processed at ${stopwatch.elapsed.inMilliseconds}ms');

    final images = codes.map((c) => QrImage.withMaskPattern(c, 3)).toList();
    debugPrint('Images processed at ${stopwatch.elapsed.inMilliseconds}ms');
    return [codes, images];
  }

  static Uint8List _generateRandomUint8List(int length) {
    final random = Random();
    return Uint8List.fromList(
      List.generate(
        length,
        (_) => random.nextInt(256),
      ), // Generate random bytes (0-255)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Code')),
      body: Center(
        child:
            _qrImages.isNotEmpty
                ? Container(
                  padding: const EdgeInsets.all(16),
                  height: MediaQuery.of(context).size.width,
                  width: MediaQuery.of(context).size.width,
                  color: Colors.white,
                  child: _qrWidget(_qrImages[index], _qrCodes[index]),
                )
                : const CircularProgressIndicator.adaptive(),
      ),
    );
  }

  Widget _qrWidget(QrImage image, QrCode qr) {
    final painter = MyQrPainter.withQr(qrImage: image, qr: qr);
    return CustomPaint(painter: painter);
  }
}
