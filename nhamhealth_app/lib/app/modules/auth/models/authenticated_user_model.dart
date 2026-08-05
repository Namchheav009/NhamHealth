class AuthenticatedUser {
  const AuthenticatedUser({
    required this.id,
    required this.email,
    required this.role,
  });

  final int id;
  final String email;
  final String role;

  factory AuthenticatedUser.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['userId'];
    return AuthenticatedUser(
      id: (rawId as num).toInt(),
      email: json['email'] as String,
      role: json['role'] as String,
    );
  }
}
