class CommunityTag {
  const CommunityTag({
    required this.id,
    required this.name,
    required this.scope,
    this.description = '',
  });

  final int id;
  final String name;
  final String scope;
  final String description;

  factory CommunityTag.fromJson(Map<String, dynamic> json) => CommunityTag(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: '${json['name'] ?? ''}'.trim(),
    scope: '${json['scope'] ?? ''}'.trim(),
    description: '${json['description'] ?? ''}'.trim(),
  );
}
