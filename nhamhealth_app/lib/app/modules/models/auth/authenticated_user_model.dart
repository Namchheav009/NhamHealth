class AuthenticatedUser {
  const AuthenticatedUser({
    required this.id,
    required this.email,
    required this.role,
    this.fullName,
    this.profileImageUrl,
    this.hasPin = false,
  });

  final int id;
  final String email;
  final String role;
  final String? fullName;
  final String? profileImageUrl;
  final bool hasPin;

  String get displayName {
    final name = fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return email.split('@').first;
  }

  String get initials {
    final parts =
        displayName
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  factory AuthenticatedUser.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['userId'];
    return AuthenticatedUser(
      id: (rawId as num).toInt(),
      email: json['email'] as String,
      role: json['role'] as String,
      fullName: json['fullName'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      hasPin: json['hasPin'] as bool? ?? false,
    );
  }
}
