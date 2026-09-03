class CommunityPerson {
  const CommunityPerson({
    required this.id,
    required this.name,
    required this.avatarUrl,
    this.detail,
    this.tags = const [],
    this.mutualFriends = 0,
    this.connectionStatus = 'NONE',
  });

  final String id;
  final String name;
  final String avatarUrl;
  final String? detail;
  final List<String> tags;
  final int mutualFriends;
  final String connectionStatus;

  /// Public community identities must never expose an email address. Older
  /// accounts may still have an email stored as their profile name, so retain
  /// a clean, readable fallback until the member updates their profile.
  String get displayName => _publicName(name);

  static String _publicName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Community member';
    if (!trimmed.contains('@')) return trimmed;

    final localPart = trimmed.split('@').first
        .replaceAll(RegExp(r'[._-]+'), ' ')
        .replaceAll(RegExp(r'(?<=[A-Za-z])(?=\d)'), ' ')
        .trim();
    if (localPart.isEmpty) return 'Community member';

    return localPart
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part.substring(0, 1).toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  factory CommunityPerson.fromJson(Map<String, dynamic> json) =>
      CommunityPerson(
        id: '${json['id'] ?? ''}',
        name: (json['name'] as String? ?? '').trim(),
        avatarUrl: (json['avatarUrl'] as String? ?? '').trim(),
        detail: (json['detail'] as String?)?.trim(),
        tags: (json['tags'] as List<dynamic>? ?? const [])
            .map((tag) => '$tag')
            .toList(growable: false),
        mutualFriends: (json['mutualFriends'] as num?)?.toInt() ?? 0,
        connectionStatus:
            (json['connectionStatus'] as String? ?? 'NONE')
                .trim()
                .toUpperCase(),
      );
}
