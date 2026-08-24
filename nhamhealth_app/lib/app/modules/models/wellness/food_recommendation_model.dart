enum FoodRecommendationType { good, warning, neutral }

class FoodRecommendationModel {
  final String title;
  final String message;
  final FoodRecommendationType type;
  final Map<String, String> titleParams;
  final Map<String, String> messageParams;

  const FoodRecommendationModel({
    required this.title,
    required this.message,
    required this.type,
    this.titleParams = const {},
    this.messageParams = const {},
  });
}
