import 'meal_plan.dart';

class AiMealRecommendationResult {
  const AiMealRecommendationResult({
    required this.recommendedMeal,
    this.alternatives = const [],
    this.aiRationale = '',
    this.actionType = 'ADD',
    this.modelUsed = '',
  });

  final PlannedMeal recommendedMeal;
  final List<PlannedMeal> alternatives;
  final String aiRationale;
  final String actionType;
  final String modelUsed;

  factory AiMealRecommendationResult.fromJson(
    Map<String, dynamic> json, {
    MealPlanSlot defaultSlot = MealPlanSlot.breakfast,
  }) {
    final recJson = Map<String, dynamic>.from(
      json['recommendedMeal'] as Map? ?? const {},
    );
    final altsRaw = json['alternatives'] as List<dynamic>? ?? const [];
    return AiMealRecommendationResult(
      recommendedMeal: PlannedMeal.fromJson(
        recJson,
      ).copyWith(slot: defaultSlot),
      alternatives:
          altsRaw
              .whereType<Map>()
              .map<PlannedMeal>(
                (m) => PlannedMeal.fromJson(
                  Map<String, dynamic>.from(m),
                ).copyWith(slot: defaultSlot),
              )
              .toList(),
      aiRationale: '${json['aiRationale'] ?? ''}'.trim(),
      actionType: '${json['actionType'] ?? 'ADD'}'.trim(),
      modelUsed: '${json['modelUsed'] ?? ''}'.trim(),
    );
  }
}
