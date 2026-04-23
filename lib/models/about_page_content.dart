import 'content_asset.dart';

class AboutPageContent {
  final String? id;
  final String heroTitle;
  final String heroSubtitle;
  final String intro;
  final List<AboutSection> sections;
  final DateTime? updatedAt;

  const AboutPageContent({
    this.id,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.intro,
    this.sections = const [],
    this.updatedAt,
  });

  const AboutPageContent.empty()
    : id = null,
      heroTitle = 'من نحن',
      heroSubtitle = '',
      intro = '',
      sections = const [],
      updatedAt = null;

  factory AboutPageContent.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'];
    return AboutPageContent(
      id: json['_id']?.toString(),
      heroTitle: (json['heroTitle'] ?? 'من نحن').toString(),
      heroSubtitle: (json['heroSubtitle'] ?? '').toString(),
      intro: (json['intro'] ?? '').toString(),
      sections: rawSections is List
          ? rawSections
                .whereType<Map<String, dynamic>>()
                .map(AboutSection.fromJson)
                .toList(growable: false)
          : const [],
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse(json['updatedAt'].toString()),
    );
  }
}

class AboutSection {
  final String? id;
  final String title;
  final String body;
  final int order;
  final List<ContentAsset> media;

  const AboutSection({
    this.id,
    required this.title,
    required this.body,
    this.order = 0,
    this.media = const [],
  });

  factory AboutSection.fromJson(Map<String, dynamic> json) {
    final rawMedia = json['media'];
    return AboutSection(
      id: json['_id']?.toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      order: json['order'] is int
          ? json['order']
          : int.tryParse(json['order']?.toString() ?? '') ?? 0,
      media: rawMedia is List
          ? rawMedia
                .whereType<Map<String, dynamic>>()
                .map(ContentAsset.fromJson)
                .toList(growable: false)
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null && id!.isNotEmpty) '_id': id,
    'title': title,
    'body': body,
    'order': order,
    'media': media.map((item) => item.toJson()).toList(growable: false),
  };
}
