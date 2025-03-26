class ReceivingFileMetadata {
  final String extension;
  final int size;
  final bool isCompressed;

  ReceivingFileMetadata({
    required this.extension,
    required this.size,
    required this.isCompressed,
  });

  @override
  String toString() {
    return '$extension;$size;compressed=$isCompressed';
  }
}
