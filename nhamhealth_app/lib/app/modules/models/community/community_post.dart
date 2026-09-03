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
    this.createdAt,
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
    this.mealName = '',
    this.cookingTimeMinutes,
    this.servings,
    this.difficulty = '',
    this.categoryId,
    this.categoryName = '',
    this.aiStatus = 'PENDING',
    this.aiReviewReason = '',
    this.mealId,
    this.ingredients = const [],
    this.steps = const [],
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
  final String mealName, difficulty, categoryName, aiStatus, aiReviewReason;
  final int? cookingTimeMinutes, servings, categoryId, mealId;
  final List<MealPostIngredient> ingredients;
  final List<MealPostStep> steps;
  final String author;
  final String role;
  final int authorId;
  final String authorAvatarUrl;
  final List<String> tags;
  final List<int> tagIds;
  final String ageLabel;
  final DateTime? createdAt;
  int likes;
  int comments;
  int shares;
  bool isLiked;
  bool isSaved;
  bool isFollowingAuthor;

  bool get isShare => sharedPost != null;

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
    createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}')?.toLocal(),
    likes: (json['likes'] as num?)?.toInt() ?? 0,
    comments: (json['comments'] as num?)?.toInt() ?? 0,
    shares: (json['shares'] as num?)?.toInt() ?? 0,
    // Spring serializes the CommunityPostResponse record components without
    // the Flutter-facing `is` prefix (followingAuthor, liked, and saved).
    // Keep accepting the normalized names as well for locally-created data.
    isFollowingAuthor:
        json['followingAuthor'] as bool? ??
        json['isFollowingAuthor'] as bool? ??
        false,
    isLiked: json['liked'] as bool? ?? json['isLiked'] as bool? ?? false,
    isSaved: json['saved'] as bool? ?? json['isSaved'] as bool? ?? false,
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
    mealName: (json['mealName'] as String? ?? '').trim(),
    cookingTimeMinutes: (json['cookingTimeMinutes'] as num?)?.toInt(),
    servings: (json['servings'] as num?)?.toInt(),
    difficulty: (json['difficulty'] as String? ?? '').trim(),
    categoryId: (json['categoryId'] as num?)?.toInt(),
    categoryName: (json['categoryName'] as String? ?? '').trim(),
    aiStatus: (json['aiStatus'] as String? ?? 'PENDING').trim(),
    aiReviewReason: (json['aiReviewReason'] as String? ?? '').trim(),
    mealId: (json['mealId'] as num?)?.toInt(),
    ingredients: (json['ingredients'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(
          (item) =>
              MealPostIngredient.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false),
    steps: (json['steps'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => MealPostStep.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false),
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
    DateTime? createdAt,
    int? likes,
    int? comments,
    int? shares,
    bool? isFollowingAuthor,
    bool? isLiked,
    bool? isSaved,
    CommunitySharedPost? sharedPost,
    String? mealName,
    int? cookingTimeMinutes,
    int? servings,
    String? difficulty,
    int? categoryId,
    String? categoryName,
    String? aiStatus,
    String? aiReviewReason,
    int? mealId,
    List<MealPostIngredient>? ingredients,
    List<MealPostStep>? steps,
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
    createdAt: createdAt ?? this.createdAt,
    likes: likes ?? this.likes,
    comments: comments ?? this.comments,
    shares: shares ?? this.shares,
    isFollowingAuthor: isFollowingAuthor ?? this.isFollowingAuthor,
    isLiked: isLiked ?? this.isLiked,
    isSaved: isSaved ?? this.isSaved,
    sharedPost: sharedPost ?? this.sharedPost,
    mealName: mealName ?? this.mealName,
    cookingTimeMinutes: cookingTimeMinutes ?? this.cookingTimeMinutes,
    servings: servings ?? this.servings,
    difficulty: difficulty ?? this.difficulty,
    categoryId: categoryId ?? this.categoryId,
    categoryName: categoryName ?? this.categoryName,
    aiStatus: aiStatus ?? this.aiStatus,
    aiReviewReason: aiReviewReason ?? this.aiReviewReason,
    mealId: mealId ?? this.mealId,
    ingredients: ingredients ?? this.ingredients,
    steps: steps ?? this.steps,
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

class MealPostIngredient {
  const MealPostIngredient({
    required this.ingredientName,
    required this.amount,
    required this.unit,
  });
  final String ingredientName;
  final num? amount;
  final String unit;
  factory MealPostIngredient.fromJson(Map<String, dynamic> json) =>
      MealPostIngredient(
        ingredientName:
            '${json['ingredientName'] ?? json['name'] ?? ''}'.trim(),
        amount: json['amount'] as num?,
        unit: '${json['unit'] ?? ''}'.trim(),
      );
  Map<String, dynamic> toJson() => {
    'name': ingredientName,
    'amount': amount,
    'unit': unit,
  };
}

class MealPostStep {
  const MealPostStep({
    required this.stepNumber,
    required this.instruction,
    this.imageUrl = '',
  });
  final int stepNumber;
  final String instruction;
  final String imageUrl;
  factory MealPostStep.fromJson(Map<String, dynamic> json) => MealPostStep(
    stepNumber:
        (json['stepNumber'] as num?)?.toInt() ??
        (json['number'] as num?)?.toInt() ??
        0,
    instruction: '${json['instruction'] ?? ''}'.trim(),
    imageUrl: '${json['imageUrl'] ?? ''}'.trim(),
  );
  Map<String, dynamic> toJson() => {'instruction': instruction};
}

class CommunitySharedPost {
  const CommunitySharedPost({
    required this.id,
    required this.authorId,
    required this.author,
    required this.role,
    required this.authorAvatarUrl,
    this.mealName = '',
    required this.description,
    required this.imageUrl,
    this.imageUrls = const [],
    this.ageLabel = 'Recently',
    this.shares = 0,
  });

  final String id;
  final int authorId;
  final String author;
  final String role;
  final String authorAvatarUrl;
  final String mealName;
  final String description;
  final String imageUrl;
  final List<String> imageUrls;
  final String ageLabel;
  final int shares;

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
      mealName: (json['mealName'] as String? ?? '').trim(),
      description: (json['description'] as String? ?? '').trim(),
      imageUrl: imageUrl,
      imageUrls:
          imageUrls.isNotEmpty
              ? imageUrls
              : imageUrl.isEmpty
              ? const []
              : [imageUrl],
      ageLabel: (json['ageLabel'] as String? ?? 'Recently').trim(),
      shares: (json['shares'] as num?)?.toInt() ?? 0,
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
        mealName: post.sharedPost?.mealName ?? post.mealName,
        description: post.sharedPost?.description ?? post.description,
        imageUrl: post.sharedPost?.imageUrl ?? post.imageUrl,
        imageUrls: post.sharedPost?.imageUrls ?? post.imageUrls,
        ageLabel: post.sharedPost?.ageLabel ?? post.ageLabel,
        shares: post.sharedPost?.shares ?? post.shares,
      );
}

enum CommunityPostVisibility {
  public(
    'PUBLIC',
    'Public',
    'Everyone in the Nham Health community',
    Icons.public_rounded,
  ),
  followers(
    'FOLLOWERS',
    'Followers',
    'Only people who follow you',
    Icons.person_outline_rounded,
  ),
  friends(
    'FRIENDS',
    'Friends',
    'People you follow who also follow you',
    Icons.group_outlined,
  ),
  onlyMe(
    'ONLY_ME',
    'Only me',
    'Only you can see this post',
    Icons.lock_outline_rounded,
  );

  const CommunityPostVisibility(
    this.apiValue,
    this.label,
    this.description,
    this.icon,
  );

  final String apiValue;
  final String label;
  final String description;
  final IconData icon;

  static CommunityPostVisibility fromApi(String value) =>
      CommunityPostVisibility.values.firstWhere(
        (item) => item.apiValue == value.trim().toUpperCase(),
        orElse: () => CommunityPostVisibility.public,
      );
}
