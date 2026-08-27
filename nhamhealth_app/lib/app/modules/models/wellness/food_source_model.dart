class FoodSourceModel {
  final String id;
  final String mealType;
  final String foodName;
  final int calories;
  final String emoji;

  const FoodSourceModel({
    required this.id,
    required this.mealType,
    required this.foodName,
    required this.calories,
    required this.emoji,
  });

  FoodSourceModel copyWith({
    String? id,
    String? mealType,
    String? foodName,
    int? calories,
    String? imagePath,
  }) {
    return FoodSourceModel(
      id: id ?? this.id,
      mealType: mealType ?? this.mealType,
      foodName: foodName ?? this.foodName,
      calories: calories ?? this.calories,
      emoji: imagePath ?? emoji,
    );
  }
}
