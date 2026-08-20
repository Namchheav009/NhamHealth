class RecommendedMealModel {
  final int id;
  final String name;
  final String image;
  final int calories;
  final String cookingTime;
  final double rating;
  final String reason;

  const RecommendedMealModel({
    required this.id,
    required this.name,
    required this.image,
    required this.calories,
    required this.cookingTime,
    required this.rating,
    this.reason = '',
  });

  factory RecommendedMealModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    if (id is! num || name is! String || name.trim().isEmpty) {
      throw const FormatException('Recommended meal data is incomplete.');
    }

    final calories = json['calories'];
    final cookingTime = json['cookingTimeMinutes'];
    final rating = json['rating'];
    return RecommendedMealModel(
      id: id.toInt(),
      name: name.trim(),
      image: (json['imageUrl'] as String? ?? '').trim(),
      calories: calories is num ? calories.round() : 0,
      cookingTime: cookingTime is num ? '${cookingTime.toInt()} min' : '',
      rating: rating is num ? rating.toDouble() : 0,
      reason: (json['reason'] as String? ?? '').trim(),
    );
  }
}
