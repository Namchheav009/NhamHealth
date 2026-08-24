import 'dart:typed_data';

class CommunityPost {
  CommunityPost({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.author,
    required this.role,
    this.authorAvatarUrl = '',
    this.tags = const [],
    this.ageLabel = 'Just now',
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.isFollowingAuthor = false,
    this.isLiked = false,
    this.isSaved = false,
    this.imageBytes,
  });

  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final Uint8List? imageBytes;
  final String author;
  final String role;
  final String authorAvatarUrl;
  final List<String> tags;
  final String ageLabel;
  int likes;
  int comments;
  int shares;
  bool isLiked;
  bool isSaved;
  bool isFollowingAuthor;

  factory CommunityPost.fromJson(Map<String, dynamic> json) => CommunityPost(
    id: '${json['id'] ?? ''}',
    title: (json['title'] as String? ?? '').trim(),
    description: (json['description'] as String? ?? '').trim(),
    imageUrl: (json['imageUrl'] as String? ?? '').trim(),
    author: (json['author'] as String? ?? '').trim(),
    role: (json['role'] as String? ?? 'Community member').trim(),
    authorAvatarUrl: (json['authorAvatarUrl'] as String? ?? '').trim(),
    tags: (json['tags'] as List<dynamic>? ?? const [])
        .map((tag) => '$tag')
        .toList(growable: false),
    ageLabel: (json['ageLabel'] as String? ?? 'Just now').trim(),
    likes: (json['likes'] as num?)?.toInt() ?? 0,
    comments: (json['comments'] as num?)?.toInt() ?? 0,
    shares: (json['shares'] as num?)?.toInt() ?? 0,
    isFollowingAuthor: json['isFollowingAuthor'] as bool? ?? false,
    isLiked: json['isLiked'] as bool? ?? false,
    isSaved: json['isSaved'] as bool? ?? false,
  );
}
