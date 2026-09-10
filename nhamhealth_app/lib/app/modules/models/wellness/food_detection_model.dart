class FoodDetectionModel {
  const FoodDetectionModel({
    required this.foodDetected,
    required this.reason,
    required this.mealName,
    required this.type,
    required this.requiresDrinkDetails,
    required this.confidence,
  });

  factory FoodDetectionModel.fromJson(Map<String, dynamic> json) =>
      FoodDetectionModel(
        foodDetected: json['foodDetected'] == true,
        reason: json['reason']?.toString() ?? '',
        mealName: json['mealName']?.toString() ?? '',
        type: json['type']?.toString() ?? 'food',
        requiresDrinkDetails: json['requiresDrinkDetails'] == true,
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      );

  final bool foodDetected;
  final String reason;
  final String mealName;
  final String type;
  final bool requiresDrinkDetails;
  final double confidence;

  bool get isDrink => type.toLowerCase() == 'drink' || requiresDrinkDetails;
}
