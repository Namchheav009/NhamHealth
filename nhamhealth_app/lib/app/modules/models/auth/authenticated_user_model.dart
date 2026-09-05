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
    if (email.contains('@')) {
      return email.split('@').first;
    }
    return email.isNotEmpty ? email : 'User';
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
    final emailValue =
        (json['email'] as String?) ??
        (json['phone'] as String?) ??
        (json['phoneNumber'] as String?) ??
        '';
    return AuthenticatedUser(
      id: (rawId as num).toInt(),
      email: emailValue,
      role: (json['role'] as String?) ?? 'USER',
      fullName: json['fullName'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      hasPin: json['hasPin'] as bool? ?? false,
    );
  }
}
