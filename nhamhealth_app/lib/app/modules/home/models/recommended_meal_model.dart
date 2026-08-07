class RecommendedMealModel {
  final int id;
  final String name;
  final String image;
  final int calories;
  final String cookingTime;
  final double rating;

  const RecommendedMealModel({
    required this.id,
    required this.name,
    required this.image,
    required this.calories,
    required this.cookingTime,
    required this.rating,
  });
}
