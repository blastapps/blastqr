class ReceivingFileMetadata {
  final int size;
  final bool isCompressed;

  ReceivingFileMetadata({required this.size, required this.isCompressed});

  @override
  String toString() {
    return '$size;compressed=$isCompressed';
  }
}
