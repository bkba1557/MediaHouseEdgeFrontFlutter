class User {
  final String id;
  final String username;
  final String email;
  final String role;
  final String customerTier;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.customerTier,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['_id'] ?? json['userId'];
    final rawUsername = json['username'] ?? json['name'] ?? json['fullName'];
    final rawEmail = json['email'];
    final rawRole =
        json['role'] ?? json['userRole'] ?? json['type'] ?? 'client';
    final rawCustomerTier = json['customerTier'] ?? json['tier'] ?? 'regular';

    return User(
      id: rawId?.toString() ?? '',
      username: rawUsername?.toString() ?? '',
      email: rawEmail?.toString() ?? '',
      role: rawRole?.toString() ?? 'client',
      customerTier: rawCustomerTier?.toString() ?? 'regular',
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isGuest => role == 'guest';

  String get tierLabel {
    switch (customerTier) {
      case 'vip':
        return 'VIP';
      case 'key_account':
        return 'Key Account';
      default:
        return 'Regular';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'customerTier': customerTier,
    };
  }
}
