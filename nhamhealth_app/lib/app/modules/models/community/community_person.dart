class CommunityPerson {
  const CommunityPerson({
    required this.id,
    required this.name,
    required this.avatarUrl,
    this.detail,
    this.tags = const [],
    this.mutualFriends = 0,
  });

  final String id;
  final String name;
  final String avatarUrl;
  final String? detail;
  final List<String> tags;
  final int mutualFriends;

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
      );
}
