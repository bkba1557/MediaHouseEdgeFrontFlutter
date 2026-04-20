class Media {
  final String id;
  final String title;
  final String description;
  final String type;
  final String url;
  final String? thumbnail;
  final String category;
  final int views;
  final DateTime createdAt;
  final String? uploadedBy;

  Media({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.url,
    this.thumbnail,
    required this.category,
    required this.views,
    required this.createdAt,
    this.uploadedBy,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['_id'],
      title: json['title'],
      description: json['description'] ?? '',
      type: json['type'],
      url: json['url'],
      thumbnail: json['thumbnail'],
      category: json['category'],
      views: json['views'],
      createdAt: DateTime.parse(json['createdAt']),
      uploadedBy: json['uploadedBy']?['username'],
    );
  }

  bool get isVideo => type == 'video';
  bool get isImage => type == 'image';
}
