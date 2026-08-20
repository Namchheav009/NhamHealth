class FavoritePost {
  const FavoritePost({
    required this.id,
    required this.author,
    required this.role,
    required this.timeAgo,
    required this.title,
    required this.body,
    required this.image,
    required this.likes,
    required this.comments,
    required this.shares,
  });

  final int id;
  final String author;
  final String role;
  final String timeAgo;
  final String title;
  final String body;
  final String image;
  final int likes;
  final int comments;
  final int shares;
}
