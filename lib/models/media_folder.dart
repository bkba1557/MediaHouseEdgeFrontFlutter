class MediaFolder {
  final String collectionKey;
  final String collectionTitle;
  final int count;
  final String? previewUrl;

  const MediaFolder({
    required this.collectionKey,
    required this.collectionTitle,
    this.count = 0,
    this.previewUrl,
  });

  factory MediaFolder.fromJson(Map<String, dynamic> json) {
    return MediaFolder(
      collectionKey: (json['collectionKey'] ?? '').toString(),
      collectionTitle: (json['collectionTitle'] ?? '').toString(),
      count: json['count'] is int
          ? json['count']
          : int.tryParse(json['count']?.toString() ?? '') ?? 0,
      previewUrl: json['previewUrl']?.toString(),
    );
  }
}
