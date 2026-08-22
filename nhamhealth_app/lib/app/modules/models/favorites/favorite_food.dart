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

  factory FavoriteFood.fromJson(Map<String, dynamic> json) => FavoriteFood(
    id: (json['id'] as num).toInt(),
    name: (json['name'] as String? ?? '').trim(),
    image: (json['imageUrl'] as String? ?? '').trim(),
    calories: (json['calories'] as num?)?.round() ?? 0,
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    category: (json['category'] as String? ?? 'Other').trim(),
  );
}
