class FoodDetectionModel {
  const FoodDetectionModel({
    required this.foodDetected,
    required this.reason,
    required this.mealName,
    required this.type,
    required this.requiresDrinkDetails,
    required this.confidence,
    this.cuisine,
    this.candidates = const [],
  });

  factory FoodDetectionModel.fromJson(Map<String, dynamic> json) =>
      FoodDetectionModel(
        foodDetected: json['foodDetected'] == true,
        reason: json['reason']?.toString() ?? '',
        mealName: json['mealName']?.toString() ?? '',
        type: json['type']?.toString() ?? 'food',
        requiresDrinkDetails: json['requiresDrinkDetails'] == true,
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
        cuisine: json['cuisine']?.toString(),
        candidates:
            (json['candidates'] as List?)
                ?.map(
                  (c) =>
                      (c is Map ? (c['name'] ?? c['mealName']) : c)
                          ?.toString()
                          .trim(),
                )
                .whereType<String>()
                .where((s) => s.isNotEmpty)
                .toList() ??
            const [],
      );

  final bool foodDetected;
  final String reason;
  final String mealName;
  final String type;
  final bool requiresDrinkDetails;
  final double confidence;
  final String? cuisine;
  final List<String> candidates;

  bool get isDrink => type.toLowerCase() == 'drink' || requiresDrinkDetails;
}
