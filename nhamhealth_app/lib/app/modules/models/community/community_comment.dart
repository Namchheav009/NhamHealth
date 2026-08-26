class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.author,
    required this.text,
    required this.createdAt,
    this.authorAvatarUrl = '',
    this.parentCommentId,
    this.likes = 0,
    this.isLiked = false,
    this.canDelete = false,
  });

  final String id;
  final String author;
  final String text;
  final String createdAt;
  final String authorAvatarUrl;
  final String? parentCommentId;
  final int likes;
  final bool isLiked;
  final bool canDelete;

  factory CommunityComment.fromJson(Map<String, dynamic> json) =>
      CommunityComment(
        id: '${json['id'] ?? ''}',
        author: '${json['author'] ?? 'Community member'}',
        text: '${json['text'] ?? ''}',
        createdAt: '${json['createdAt'] ?? ''}',
        authorAvatarUrl: '${json['authorAvatarUrl'] ?? ''}',
        parentCommentId:
            json['parentCommentId'] == null ? null : '${json['parentCommentId']}',
        likes: (json['likes'] as num?)?.toInt() ?? 0,
        isLiked: json['liked'] as bool? ?? false,
        canDelete: json['canDelete'] as bool? ?? false,
      );
}
