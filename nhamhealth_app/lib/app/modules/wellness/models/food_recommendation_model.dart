enum FoodRecommendationType { good, warning, neutral }

class FoodRecommendationModel {
  final String title;
  final String message;
  final FoodRecommendationType type;

  const FoodRecommendationModel({
    required this.title,
    required this.message,
    required this.type,
  });
}
