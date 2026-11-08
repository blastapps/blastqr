import 'package:blast_qr/model/file_wrapper.dart';
import 'package:flutter/foundation.dart';

/// Sends larger than this get a warning first.
const largeTransferBytes = 2500000;

/// Images up to this size aren't worth re-encoding.
const minCompressibleImageBytes = 400000;

bool isCompressibleImage(FileWrapper file) =>
    file.type.allowsImageCompression && file.size > minCompressibleImageBytes;

/// Zips the files into one bundle, re-encoding images if asked.
typedef ZipFiles = Future<FileWrapper> Function({required bool compressImages});

/// What happens before a send starts: whether a long transfer is warned
/// about, whether images are compressed, and when several files are zipped
/// into one bundle.
///
/// A bundle's images are compressed while zipping, so a bundle is zipped as
/// soon as that choice is made: right away, unless the warning has to offer
/// compressing first.
class SendPlan extends ChangeNotifier {
  SendPlan(this.files, {required bool compressImages, required this.zip}) {
    _compressibleImages = files.where(isCompressibleImage).length;
    _compressImages = compressImages && _compressibleImages > 0;
    if (!isBundle) {
      _file = files.single;
      // A single image's compressed size is only known once sending starts.
      _acknowledged = _compressImages;
    } else if (compressibleImages == 0 || !_isLarge) {
      _zip();
    }
  }

  final List<FileWrapper> files;
  final ZipFiles zip;

  bool get isBundle => files.length > 1;

  /// What gets sent: the single file, or the bundle once zipped.
  FileWrapper? get file => _file;
  FileWrapper? _file;

  /// Whether images are re-encoded at a lower quality.
  bool get compressImages => _compressImages;
  bool _compressImages = false;

  /// How many images the warning offers to compress.
  int get compressibleImages => _compressImages ? 0 : _compressibleImages;
  late final int _compressibleImages;

  bool get isZipping => _zipping;
  bool _zipping = false;

  bool _acknowledged = false;
  bool _disposed = false;

  /// Bytes to send, before gzip and encryption.
  int get size => _file?.size ?? files.fold(0, (sum, f) => sum + f.size);

  bool get _isLarge => size > largeTransferBytes;

  bool get showsWarning => !_zipping && !_acknowledged && _isLarge;

  void sendAsIs() {
    _acknowledged = true;
    if (_file == null) _zip();
    notifyListeners();
  }

  void sendCompressed() {
    _acknowledged = true;
    _compressImages = true;
    if (isBundle) _zip();
    notifyListeners();
  }

  Future<void> _zip() async {
    _zipping = true;
    final bundle = await zip(compressImages: _compressImages);
    if (_disposed) {
      await bundle.file.delete();
      return;
    }
    _file = bundle;
    _zipping = false;
    notifyListeners();
  }

  /// Also deletes the bundle, now or once zipping finishes.
  @override
  void dispose() {
    _disposed = true;
    if (isBundle) _file?.file.delete();
    super.dispose();
  }
}
