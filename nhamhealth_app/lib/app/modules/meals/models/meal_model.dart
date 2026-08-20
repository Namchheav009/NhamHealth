class MealModel {
  MealModel({
    required this.id,
    required this.name,
    required this.calories,
    required this.image,
    required this.category,
    required this.categoryId,
    this.isFavorite = false,
  });

  final int id;
  final String name;
  final int calories;
  final String image;
  final String category;
  final int categoryId;
  bool isFavorite;

  factory MealModel.fromJson(
    Map<String, dynamic> json, {
    required String baseUrl,
  }) {
    final id = json['id'];
    final name = (json['name'] as String? ?? '').trim();
    if (id is! num || name.isEmpty) {
      throw const FormatException('Meal data is incomplete.');
    }
    final rawImage = (json['imageUrl'] as String? ?? '').trim();
    return MealModel(
      id: id.toInt(),
      name: name,
      calories: (json['calories'] as num?)?.round() ?? 0,
      image: rawImage.startsWith('/') ? '$baseUrl$rawImage' : rawImage,
      category: (json['category'] as String? ?? 'Uncategorized').trim(),
      categoryId: (json['categoryId'] as num?)?.toInt() ?? 0,
    );
  }
}
