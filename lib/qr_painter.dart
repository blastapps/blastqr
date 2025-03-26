/*
 * QR.Flutter
 * Copyright (c) 2019 the QR.Flutter authors.
 * See LICENSE for distribution and usage details.
 */

import 'package:flutter/widgets.dart';
import 'package:qr/qr.dart';

/// Represents a specific element / part of a QR code. This is used to isolate
/// the different parts so that we can style and modify specific parts
/// independently.
enum QrCodeElement {
  /// The 'stroke' / outer square of the QR code finder pattern element.
  finderPatternOuter,

  /// The inner/in-between square of the QR code finder pattern element.
  finderPatternInner,

  /// The "dot" square of the QR code finder pattern element.
  finderPatternDot,

  /// The individual pixels of the QR code
  codePixel,

  /// The "empty" pixels of the QR code
  codePixelEmpty,
}

/// Enumeration representing the three finder pattern (square 'eye') locations.
enum FinderPatternPosition {
  /// The top left position.
  topLeft,

  /// The top right position.
  topRight,

  /// The bottom left position.
  bottomLeft,
}

const int _finderPatternLimit = 7;

/// A [CustomPainter] object that you can use to paint a QR code.
class QrPainter extends CustomPainter {
  /// Create a new QrPainter with a pre-validated/created [QrCode] object. This
  /// constructor is useful when you have a custom validation / error handling
  /// flow or for when you need to pre-validate the QR data.
  QrPainter.withQr({required QrImage qrImage, required QrCode qr})
    : _qrImage = qrImage,
      _qr = qr,
      version = qr.typeNumber,
      errorCorrectionLevel = qr.errorCorrectLevel {
    _initPaints();
  }

  /// The QR code version.
  final int version; // the qr code version

  /// The error correction level of the QR code.
  final int errorCorrectionLevel; // the qr code error correction level

  /// The base QR code data
  final QrCode _qr;

  /// QR Image renderer
  late final QrImage _qrImage;

  /// Cache for all of the [Paint] objects.
  final PaintCache _paintCache = PaintCache();

  void _initPaints() {
    // Cache the pixel paint object. For now there is only one but we might
    // expand it to multiple later (e.g.: different colours).
    _paintCache.cache(
      Paint()..style = PaintingStyle.fill,
      QrCodeElement.codePixel,
    );
    // Cache the empty pixel paint object. Empty color is deprecated and will go
    // away.
    _paintCache.cache(
      Paint()..style = PaintingStyle.fill,
      QrCodeElement.codePixelEmpty,
    );
    // Cache the finder pattern painters. We'll keep one for each one in case
    // we want to provide customization options later.
    for (final position in FinderPatternPosition.values) {
      _paintCache.cache(
        Paint()..style = PaintingStyle.stroke,
        QrCodeElement.finderPatternOuter,
        position: position,
      );
      _paintCache.cache(
        Paint()..style = PaintingStyle.stroke,
        QrCodeElement.finderPatternInner,
        position: position,
      );
      _paintCache.cache(
        Paint()..style = PaintingStyle.fill,
        QrCodeElement.finderPatternDot,
        position: position,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // if the widget has a zero size side then we cannot continue painting.
    if (size.shortestSide == 0) {
      debugPrint(
        "[QR] WARN: width or height is zero. You should set a 'size' value "
        'or nest this painter in a Widget that defines a non-zero size',
      );
      return;
    }

    final paintMetrics = _PaintMetrics(
      containerSize: size.shortestSide,
      moduleCount: _qr.moduleCount,
    );

    // draw the finder pattern elements
    _drawFinderPatternItem(FinderPatternPosition.topLeft, canvas, paintMetrics);
    _drawFinderPatternItem(
      FinderPatternPosition.bottomLeft,
      canvas,
      paintMetrics,
    );
    _drawFinderPatternItem(
      FinderPatternPosition.topRight,
      canvas,
      paintMetrics,
    );

    // get the painters for the pixel information
    final pixelPaint = _paintCache.firstPaint(QrCodeElement.codePixel);
    pixelPaint!.color = const Color(0xff000000);

    _drawDots2(paintMetrics, pixelPaint, canvas);
  }

  void _drawDots2(_PaintMetrics paintMetrics, Paint paint, Canvas canvas) {
    double left;
    double top;

    int rectCount = 0;
    final pixelPath = Path();
    final pixelPath2 = Path();
    for (var x = 0; x < _qr.moduleCount; x++) {
      for (var y = 0; y < _qr.moduleCount; y++) {
        // draw the finder patterns independently
        if (_isFinderPatternPosition(x, y)) {
          continue;
        }
        if (_qrImage.isDark(y, x) == false) {
          continue;
        }
        // paint a pixel
        left = (x * (paintMetrics.pixelSize));
        top = (y * (paintMetrics.pixelSize));
        var pixelHTweak = 0.0;
        var pixelVTweak = 0.0;
        if (_hasAdjacentHorizontalPixel(x, y, _qr.moduleCount)) {
          pixelHTweak = 0.5;
        }
        if (_hasAdjacentVerticalPixel(x, y, _qr.moduleCount)) {
          pixelVTweak = 0.5;
        }
        final squareRect = Rect.fromLTWH(
          left,
          top,
          paintMetrics.pixelSize + pixelHTweak,
          paintMetrics.pixelSize + pixelVTweak,
        );
        if (rectCount >= 10000) {
          pixelPath2.addRect(squareRect);
        } else {
          pixelPath.addRect(squareRect);
        }
        rectCount++;
      }
    }

    canvas.drawPath(pixelPath, paint);
    canvas.drawPath(pixelPath2, paint);
  }

  bool _hasAdjacentVerticalPixel(int x, int y, int moduleCount) {
    if (y + 1 >= moduleCount) {
      return false;
    }
    return _qrImage.isDark(y + 1, x);
  }

  bool _hasAdjacentHorizontalPixel(int x, int y, int moduleCount) {
    if (x + 1 >= moduleCount) {
      return false;
    }
    return _qrImage.isDark(y, x + 1);
  }

  bool _isFinderPatternPosition(int x, int y) {
    final isTopLeft = y < _finderPatternLimit && x < _finderPatternLimit;
    final isBottomLeft =
        y < _finderPatternLimit && (x >= _qr.moduleCount - _finderPatternLimit);
    final isTopRight =
        y >= _qr.moduleCount - _finderPatternLimit && (x < _finderPatternLimit);
    return isTopLeft || isBottomLeft || isTopRight;
  }

  void _drawFinderPatternItem(
    FinderPatternPosition position,
    Canvas canvas,
    _PaintMetrics metrics,
  ) {
    final radius =
        (_finderPatternLimit * metrics.pixelSize) - metrics.pixelSize;
    final strokeAdjust = metrics.pixelSize / 2.0;
    final edgePos = (metrics.innerContentSize) - (radius + strokeAdjust);

    Offset offset;
    if (position == FinderPatternPosition.topLeft) {
      offset = Offset(strokeAdjust, strokeAdjust);
    } else if (position == FinderPatternPosition.bottomLeft) {
      offset = Offset(strokeAdjust, edgePos);
    } else {
      offset = Offset(edgePos, strokeAdjust);
    }

    // configure the paints
    final outerPaint =
        _paintCache.firstPaint(
          QrCodeElement.finderPatternOuter,
          position: position,
        )!;
    outerPaint.strokeWidth = metrics.pixelSize;
    outerPaint.color = const Color(0xff000000);

    final innerPaint =
        _paintCache.firstPaint(
          QrCodeElement.finderPatternInner,
          position: position,
        )!;
    innerPaint.strokeWidth = metrics.pixelSize;
    innerPaint.color = const Color(0x00ffffff);

    final dotPaint = _paintCache.firstPaint(
      QrCodeElement.finderPatternDot,
      position: position,
    );
    dotPaint!.color = const Color(0xff000000);

    final outerRect = Rect.fromLTWH(offset.dx, offset.dy, radius, radius);

    final innerRadius = radius - (2 * metrics.pixelSize);
    final innerRect = Rect.fromLTWH(
      offset.dx + metrics.pixelSize,
      offset.dy + metrics.pixelSize,
      innerRadius,
      innerRadius,
    );

    final gap = metrics.pixelSize * 2;
    final dotSize = radius - gap - (2 * strokeAdjust);
    final dotRect = Rect.fromLTWH(
      offset.dx + metrics.pixelSize + strokeAdjust,
      offset.dy + metrics.pixelSize + strokeAdjust,
      dotSize,
      dotSize,
    );

    canvas.drawRect(outerRect, outerPaint);
    canvas.drawRect(innerRect, innerPaint);
    canvas.drawRect(dotRect, dotPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldPainter) {
    if (oldPainter is QrPainter) {
      return errorCorrectionLevel != oldPainter.errorCorrectionLevel ||
          _qr != oldPainter._qr;
    }
    return true;
  }
}

class _PaintMetrics {
  _PaintMetrics({required this.containerSize, required this.moduleCount}) {
    _calculateMetrics();
  }

  final int moduleCount;
  final double containerSize;

  late final double _pixelSize;
  double get pixelSize => _pixelSize;

  late final double _innerContentSize;
  double get innerContentSize => _innerContentSize;

  void _calculateMetrics() {
    _pixelSize = (containerSize) / moduleCount;
    _innerContentSize = (_pixelSize * moduleCount);
  }
}

/// Caches painter objects so we do have to recreate them and waste expensive
/// cycles.
class PaintCache {
  final List<Paint> _pixelPaints = <Paint>[];
  final Map<String, Paint> _keyedPaints = <String, Paint>{};

  String _cacheKey(QrCodeElement element, {FinderPatternPosition? position}) {
    final posKey = position != null ? position.toString() : 'any';
    return '$element:$posKey';
  }

  /// Save a [Paint] for the provided element and position into the cache.
  void cache(
    Paint paint,
    QrCodeElement element, {
    FinderPatternPosition? position,
  }) {
    if (element == QrCodeElement.codePixel) {
      _pixelPaints.add(paint);
    } else {
      _keyedPaints[_cacheKey(element, position: position)] = paint;
    }
  }

  /// Retrieve the first [Paint] object from the paint cache for the provided
  /// element and position.
  Paint? firstPaint(QrCodeElement element, {FinderPatternPosition? position}) {
    return element == QrCodeElement.codePixel
        ? _pixelPaints.first
        : _keyedPaints[_cacheKey(element, position: position)];
  }

  /// Retrieve all [Paint] objects from the paint cache for the provided
  /// element and position. Note: Finder pattern elements can only have a max
  /// one [Paint] object per position. As such they will always return a [List]
  /// with a fixed size of `1`.
  List<Paint?> paints(
    QrCodeElement element, {
    FinderPatternPosition? position,
  }) {
    return element == QrCodeElement.codePixel
        ? _pixelPaints
        : <Paint?>[_keyedPaints[_cacheKey(element, position: position)]];
  }
}
