class ReceivingFileMetadata {
  final int size;
  final bool isCompressed;
  final bool isEncrypted;

  ReceivingFileMetadata({
    required this.size,
    required this.isCompressed,
    required this.isEncrypted,
  });

  @override
  String toString() {
    return '$size;compressed=$isCompressed;encrypted=$isEncrypted';
  }
}
