import 'dart:typed_data';

import 'package:flutter/material.dart';

class CommunityPost {
  CommunityPost({
    required this.id,
    required this.description,
    required this.imageUrl,
    this.imageUrls = const [],
    required this.author,
    required this.role,
    this.authorId = 0,
    this.authorAvatarUrl = '',
    this.tags = const [],
    this.tagIds = const [],
    this.ageLabel = 'Just now',
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.isFollowingAuthor = false,
    this.isLiked = false,
    this.isSaved = false,
    this.imageBytes,
    this.visibility = CommunityPostVisibility.public,
    this.allowComments = true,
    this.allowReplies = true,
    this.sharedPost,
  });

  final String id;
  final String description;
  final String imageUrl;
  final List<String> imageUrls;
  final Uint8List? imageBytes;
  final CommunityPostVisibility visibility;
  final bool allowComments;
  final bool allowReplies;
  final CommunitySharedPost? sharedPost;
  final String author;
  final String role;
  final int authorId;
  final String authorAvatarUrl;
  final List<String> tags;
  final List<int> tagIds;
  final String ageLabel;
  int likes;
  int comments;
  int shares;
  bool isLiked;
  bool isSaved;
  bool isFollowingAuthor;

  factory CommunityPost.fromJson(Map<String, dynamic> json) => CommunityPost(
    id: '${json['id'] ?? ''}',
    description: (json['description'] as String? ?? '').trim(),
    imageUrl: (json['imageUrl'] as String? ?? '').trim(),
    imageUrls: _imageUrls(json),
    authorId: (json['authorId'] as num?)?.toInt() ?? 0,
    author: (json['author'] as String? ?? '').trim(),
    role: (json['role'] as String? ?? 'Community member').trim(),
    authorAvatarUrl: (json['authorAvatarUrl'] as String? ?? '').trim(),
    tags: (json['tags'] as List<dynamic>? ?? const [])
        .map((tag) => '$tag')
        .toList(growable: false),
    tagIds: (json['tagIds'] as List<dynamic>? ?? const [])
        .map((tag) => (tag as num?)?.toInt())
        .whereType<int>()
        .toList(growable: false),
    ageLabel: (json['ageLabel'] as String? ?? 'Just now').trim(),
    likes: (json['likes'] as num?)?.toInt() ?? 0,
    comments: (json['comments'] as num?)?.toInt() ?? 0,
    shares: (json['shares'] as num?)?.toInt() ?? 0,
    isFollowingAuthor: json['isFollowingAuthor'] as bool? ?? false,
    isLiked: json['isLiked'] as bool? ?? false,
    isSaved: json['isSaved'] as bool? ?? false,
    visibility: CommunityPostVisibility.fromApi(
      json['visibility'] as String? ?? 'PUBLIC',
    ),
    allowComments: json['allowComments'] as bool? ?? true,
    allowReplies: json['allowReplies'] as bool? ?? true,
    sharedPost:
        json['sharedPost'] is Map
            ? CommunitySharedPost.fromJson(
              Map<String, dynamic>.from(json['sharedPost'] as Map),
            )
            : null,
  );

  CommunityPost copyWith({
    String? description,
    String? imageUrl,
    List<String>? imageUrls,
    Uint8List? imageBytes,
    CommunityPostVisibility? visibility,
    bool? allowComments,
    bool? allowReplies,
    String? author,
    String? role,
    int? authorId,
    String? authorAvatarUrl,
    List<String>? tags,
    List<int>? tagIds,
    String? ageLabel,
    int? likes,
    int? comments,
    int? shares,
    bool? isFollowingAuthor,
    bool? isLiked,
    bool? isSaved,
    CommunitySharedPost? sharedPost,
  }) => CommunityPost(
    id: id,
    description: description ?? this.description,
    imageUrl: imageUrl ?? this.imageUrl,
    imageUrls: imageUrls ?? this.imageUrls,
    imageBytes: imageBytes ?? this.imageBytes,
    visibility: visibility ?? this.visibility,
    allowComments: allowComments ?? this.allowComments,
    allowReplies: allowReplies ?? this.allowReplies,
    author: author ?? this.author,
    role: role ?? this.role,
    authorId: authorId ?? this.authorId,
    authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
    tags: tags ?? this.tags,
    tagIds: tagIds ?? this.tagIds,
    ageLabel: ageLabel ?? this.ageLabel,
    likes: likes ?? this.likes,
    comments: comments ?? this.comments,
    shares: shares ?? this.shares,
    isFollowingAuthor: isFollowingAuthor ?? this.isFollowingAuthor,
    isLiked: isLiked ?? this.isLiked,
    isSaved: isSaved ?? this.isSaved,
    sharedPost: sharedPost ?? this.sharedPost,
  );

  static List<String> _imageUrls(Map<String, dynamic> json) {
    final urls = (json['imageUrls'] as List<dynamic>? ?? const [])
        .map((url) => '$url'.trim())
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
    if (urls.isNotEmpty) return urls;
    final imageUrl = (json['imageUrl'] as String? ?? '').trim();
    return imageUrl.isEmpty ? const [] : [imageUrl];
  }
}

class CommunitySharedPost {
  const CommunitySharedPost({
    required this.id,
    required this.authorId,
    required this.author,
    required this.role,
    required this.authorAvatarUrl,
    required this.description,
    required this.imageUrl,
    this.imageUrls = const [],
    this.ageLabel = 'Recently',
  });

  final String id;
  final int authorId;
  final String author;
  final String role;
  final String authorAvatarUrl;
  final String description;
  final String imageUrl;
  final List<String> imageUrls;
  final String ageLabel;

  factory CommunitySharedPost.fromJson(Map<String, dynamic> json) {
    final imageUrls = (json['imageUrls'] as List<dynamic>? ?? const [])
        .map((url) => '$url'.trim())
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
    final imageUrl = (json['imageUrl'] as String? ?? '').trim();
    return CommunitySharedPost(
      id: '${json['id'] ?? ''}',
      authorId: (json['authorId'] as num?)?.toInt() ?? 0,
      author: (json['author'] as String? ?? 'Community member').trim(),
      role: (json['role'] as String? ?? 'Community member').trim(),
      authorAvatarUrl: (json['authorAvatarUrl'] as String? ?? '').trim(),
      description: (json['description'] as String? ?? '').trim(),
      imageUrl: imageUrl,
      imageUrls:
          imageUrls.isNotEmpty
              ? imageUrls
              : imageUrl.isEmpty
              ? const []
              : [imageUrl],
      ageLabel: (json['ageLabel'] as String? ?? 'Recently').trim(),
    );
  }

  factory CommunitySharedPost.fromPost(CommunityPost post) =>
      CommunitySharedPost(
        id: post.sharedPost?.id ?? post.id,
        authorId: post.sharedPost?.authorId ?? post.authorId,
        author: post.sharedPost?.author ?? post.author,
        role: post.sharedPost?.role ?? post.role,
        authorAvatarUrl:
            post.sharedPost?.authorAvatarUrl ?? post.authorAvatarUrl,
        description: post.sharedPost?.description ?? post.description,
        imageUrl: post.sharedPost?.imageUrl ?? post.imageUrl,
        imageUrls: post.sharedPost?.imageUrls ?? post.imageUrls,
        ageLabel: post.sharedPost?.ageLabel ?? post.ageLabel,
      );
}

enum CommunityPostVisibility {
  public('PUBLIC', 'Public', Icons.public_rounded),
  friends('FRIENDS', 'Friends', Icons.group_outlined),
  onlyMe('ONLY_ME', 'Only me', Icons.lock_outline_rounded);

  const CommunityPostVisibility(this.apiValue, this.label, this.icon);

  final String apiValue;
  final String label;
  final IconData icon;

  static CommunityPostVisibility fromApi(String value) =>
      CommunityPostVisibility.values.firstWhere(
        (item) => item.apiValue == value.trim().toUpperCase(),
        orElse: () => CommunityPostVisibility.public,
      );
}
