class AdminUser {
  final String id;
  final String username;
  final String email;
  final String role;
  final String customerTier;
  final int notificationTokenCount;
  final DateTime? createdAt;

  const AdminUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.customerTier,
    required this.notificationTokenCount,
    this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt']?.toString();

    return AdminUser(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'client').toString(),
      customerTier: (json['customerTier'] ?? 'regular').toString(),
      notificationTokenCount: json['notificationTokenCount'] is num
          ? (json['notificationTokenCount'] as num).toInt()
          : 0,
      createdAt: createdAtRaw == null ? null : DateTime.tryParse(createdAtRaw),
    );
  }

  AdminUser copyWith({String? customerTier}) {
    return AdminUser(
      id: id,
      username: username,
      email: email,
      role: role,
      customerTier: customerTier ?? this.customerTier,
      notificationTokenCount: notificationTokenCount,
      createdAt: createdAt,
    );
  }

  bool get isClient => role == 'client';
}
