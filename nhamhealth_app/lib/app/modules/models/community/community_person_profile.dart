class CommunityPersonProfile {
  const CommunityPersonProfile({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.role,
    required this.headline,
    required this.joinedLabel,
    required this.verified,
    required this.posts,
    required this.followers,
    required this.following,
    required this.isFollowing,
  });

  final int id;
  final String name;
  final String avatarUrl;
  final String role;
  final String headline;
  final String joinedLabel;
  final bool verified;
  final int posts;
  final int followers;
  final int following;
  final bool isFollowing;

  factory CommunityPersonProfile.fromJson(Map<String, dynamic> json) =>
      CommunityPersonProfile(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: '${json['name'] ?? 'Community member'}'.trim(),
        avatarUrl: '${json['avatarUrl'] ?? ''}'.trim(),
        role: '${json['role'] ?? 'Community member'}'.trim(),
        headline: '${json['headline'] ?? ''}'.trim(),
        joinedLabel: '${json['joinedLabel'] ?? ''}'.trim(),
        verified: json['verified'] == true,
        posts: (json['posts'] as num?)?.toInt() ?? 0,
        followers: (json['followers'] as num?)?.toInt() ?? 0,
        following: (json['following'] as num?)?.toInt() ?? 0,
        isFollowing: json['followingAuthor'] == true,
      );
}
