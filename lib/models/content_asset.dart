class ContentAsset {
  final String? id;
  final String title;
  final String description;
  final String type;
  final String url;
  final String? thumbnail;

  const ContentAsset({
    this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.url,
    this.thumbnail,
  });

  factory ContentAsset.fromJson(Map<String, dynamic> json) {
    return ContentAsset(
      id: json['_id']?.toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      type: (json['type'] ?? 'image').toString().trim().toLowerCase(),
      url: (json['url'] ?? '').toString(),
      thumbnail: json['thumbnail']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null && id!.isNotEmpty) '_id': id,
    'title': title,
    'description': description,
    'type': type,
    'url': url,
    if (thumbnail != null && thumbnail!.trim().isNotEmpty)
      'thumbnail': thumbnail,
  };

  bool get isVideo => type == 'video';
  bool get isImage => type == 'image';

  String? get previewUrl {
    if (isVideo) {
      final thumb = thumbnail?.trim() ?? '';
      return thumb.isEmpty ? null : thumb;
    }
    return url.trim().isEmpty ? null : url;
  }
}
