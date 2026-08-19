class FavoriteFood {
  const FavoriteFood({
    required this.id,
    required this.name,
    required this.image,
    required this.calories,
    required this.rating,
    required this.category,
  });

  final int id;
  final String name;
  final String image;
  final int calories;
  final double rating;
  final String category;
}
