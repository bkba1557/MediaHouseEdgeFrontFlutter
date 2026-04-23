import 'content_asset.dart';

class TeamMemberComment {
  final String id;
  final String authorName;
  final String message;
  final DateTime? createdAt;

  const TeamMemberComment({
    required this.id,
    required this.authorName,
    required this.message,
    this.createdAt,
  });

  factory TeamMemberComment.fromJson(Map<String, dynamic> json) {
    return TeamMemberComment(
      id: (json['_id'] ?? '').toString(),
      authorName: (json['authorName'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString()),
    );
  }
}

class TeamMember {
  final String id;
  final String name;
  final String role;
  final String bio;
  final String photoUrl;
  final List<String> skills;
  final List<ContentAsset> portfolio;
  final List<TeamMemberComment> comments;
  final int order;
  final int viewsCount;
  final int likesCount;
  final int commentsCount;
  final double viewSharePercent;
  final bool likedByCurrentActor;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TeamMember({
    required this.id,
    required this.name,
    required this.role,
    required this.bio,
    required this.photoUrl,
    this.skills = const [],
    this.portfolio = const [],
    this.comments = const [],
    this.order = 0,
    this.viewsCount = 0,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.viewSharePercent = 0,
    this.likedByCurrentActor = false,
    this.createdAt,
    this.updatedAt,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    final rawSkills = json['skills'];
    final rawPortfolio = json['portfolio'];
    final rawComments = json['comments'];

    return TeamMember(
      id: (json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      bio: (json['bio'] ?? '').toString(),
      photoUrl: (json['photoUrl'] ?? '').toString(),
      skills: rawSkills is List
          ? rawSkills.map((item) => item.toString()).toList(growable: false)
          : const [],
      portfolio: rawPortfolio is List
          ? rawPortfolio
                .whereType<Map<String, dynamic>>()
                .map(ContentAsset.fromJson)
                .toList(growable: false)
          : const [],
      comments: rawComments is List
          ? rawComments
                .whereType<Map<String, dynamic>>()
                .map(TeamMemberComment.fromJson)
                .toList(growable: false)
          : const [],
      order: json['order'] is int
          ? json['order']
          : int.tryParse(json['order']?.toString() ?? '') ?? 0,
      viewsCount: json['viewsCount'] is int
          ? json['viewsCount']
          : int.tryParse(json['viewsCount']?.toString() ?? '') ?? 0,
      likesCount: json['likesCount'] is int
          ? json['likesCount']
          : int.tryParse(json['likesCount']?.toString() ?? '') ?? 0,
      commentsCount: json['commentsCount'] is int
          ? json['commentsCount']
          : int.tryParse(json['commentsCount']?.toString() ?? '') ?? 0,
      viewSharePercent: json['viewSharePercent'] is num
          ? (json['viewSharePercent'] as num).toDouble()
          : double.tryParse(json['viewSharePercent']?.toString() ?? '') ?? 0,
      likedByCurrentActor: json['likedByCurrentActor'] == true,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString()),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse(json['updatedAt'].toString()),
    );
  }

  TeamMember copyWith({
    String? id,
    String? name,
    String? role,
    String? bio,
    String? photoUrl,
    List<String>? skills,
    List<ContentAsset>? portfolio,
    List<TeamMemberComment>? comments,
    int? order,
    int? viewsCount,
    int? likesCount,
    int? commentsCount,
    double? viewSharePercent,
    bool? likedByCurrentActor,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeamMember(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      skills: skills ?? this.skills,
      portfolio: portfolio ?? this.portfolio,
      comments: comments ?? this.comments,
      order: order ?? this.order,
      viewsCount: viewsCount ?? this.viewsCount,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      viewSharePercent: viewSharePercent ?? this.viewSharePercent,
      likedByCurrentActor: likedByCurrentActor ?? this.likedByCurrentActor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
