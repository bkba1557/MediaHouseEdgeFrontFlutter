class Media {
  final String id;
  final String title;
  final String description;
  final String type;
  final String url;
  final String? thumbnail;
  final List<MediaCrewMember> crew;
  final String category;
  final String? collectionKey;
  final String? collectionTitle;
  final int? sequence;
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
    this.crew = const [],
    required this.category,
    this.collectionKey,
    this.collectionTitle,
    this.sequence,
    required this.views,
    required this.createdAt,
    this.uploadedBy,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] ?? '').toString();
    final normalizedType = rawType.trim().toLowerCase();
    final rawCrew = json['crew'];
    final crew = rawCrew is List
        ? rawCrew
              .whereType<Map<String, dynamic>>()
              .map(MediaCrewMember.fromJson)
              .toList(growable: false)
        : const <MediaCrewMember>[];
    return Media(
      id: json['_id'],
      title: json['title'],
      description: json['description'] ?? '',
      type: normalizedType.isEmpty ? rawType : normalizedType,
      url: json['url'],
      thumbnail: json['thumbnail'],
      crew: crew,
      category: json['category'],
      collectionKey: json['collectionKey'],
      collectionTitle: json['collectionTitle'],
      sequence: json['sequence'] is int
          ? json['sequence']
          : int.tryParse(json['sequence']?.toString() ?? ''),
      views: json['views'],
      createdAt: DateTime.parse(json['createdAt']),
      uploadedBy: json['uploadedBy']?['username'],
    );
  }

  bool get isVideo => type.trim().toLowerCase() == 'video';
  bool get isImage => type.trim().toLowerCase() == 'image';

  /// URL for showing a preview image in grids/cards.
  ///
  /// - Images: uses [url].
  /// - Videos: uses [thumbnail] when available.
  ///
  /// Returns null when there is no safe preview image (e.g. video without a
  /// cover/thumbnail).
  String? get previewImageUrl {
    // Treat any unknown type as image for preview purposes (so old/legacy data
    // like "IMAGE" keeps working on the web).
    if (!isVideo) return url;

    final thumb = (thumbnail ?? '').trim();
    if (thumb.isNotEmpty) return thumb;
    return null;
  }
}

class MediaCrewMember {
  final String name;
  final String role;
  final String photoUrl;

  const MediaCrewMember({
    required this.name,
    required this.role,
    required this.photoUrl,
  });

  factory MediaCrewMember.fromJson(Map<String, dynamic> json) {
    return MediaCrewMember(
      name: (json['name'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      photoUrl: (json['photoUrl'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'role': role,
    'photoUrl': photoUrl,
  };
}
