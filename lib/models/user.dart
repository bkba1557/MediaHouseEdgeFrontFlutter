class User {
  final String id;
  final String username;
  final String email;
  final String role;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['_id'] ?? json['userId'];
    final rawUsername = json['username'] ?? json['name'] ?? json['fullName'];
    final rawEmail = json['email'];
    final rawRole = json['role'] ?? json['userRole'] ?? json['type'] ?? 'client';

    return User(
      id: rawId?.toString() ?? '',
      username: rawUsername?.toString() ?? '',
      email: rawEmail?.toString() ?? '',
      role: rawRole?.toString() ?? 'client',
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isGuest => role == 'guest';
}
