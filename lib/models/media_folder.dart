class MediaFolder {
  final String collectionKey;
  final String collectionTitle;
  final int count;
  final String? previewUrl;
  final int? sortOrder;

  const MediaFolder({
    required this.collectionKey,
    required this.collectionTitle,
    this.count = 0,
    this.previewUrl,
    this.sortOrder,
  });

  factory MediaFolder.fromJson(Map<String, dynamic> json) {
    return MediaFolder(
      collectionKey: (json['collectionKey'] ?? '').toString(),
      collectionTitle: (json['collectionTitle'] ?? '').toString(),
      count: json['count'] is int
          ? json['count']
          : int.tryParse(json['count']?.toString() ?? '') ?? 0,
      previewUrl: json['previewUrl']?.toString(),
      sortOrder: json['sortOrder'] is int
          ? json['sortOrder']
          : int.tryParse(json['sortOrder']?.toString() ?? ''),
    );
  }
}
