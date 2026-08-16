class FoodNutritionModel {
  final int? id;
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double sugar;
  final double servingSize;
  final String servingUnit;
  final double confidence;
  final String recommendationTitle;
  final String recommendation;

  const FoodNutritionModel({
    this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.sugar,
    required this.servingSize,
    required this.servingUnit,
    this.confidence = 0,
    this.recommendationTitle = 'AI Recommendation',
    this.recommendation = '',
  });

  factory FoodNutritionModel.fromJson(Map<String, dynamic> json) =>
      FoodNutritionModel(
        id: _integer(json['id']),
        name: json['name']?.toString() ?? 'Unknown food',
        calories: _number(json['calories']),
        protein: _number(json['protein']),
        carbs: _number(json['carbs']),
        fat: _number(json['fat']),
        sugar: _number(json['sugar']),
        servingSize: _number(json['servingSize'], fallback: 1),
        servingUnit: json['servingUnit']?.toString() ?? 'serving',
        confidence: _number(json['confidence']),
        recommendationTitle:
            json['recommendationTitle']?.toString() ?? 'AI Recommendation',
        recommendation: json['recommendation']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'sugar': sugar,
    'servingSize': servingSize,
    'servingUnit': servingUnit,
    'confidence': confidence,
    'recommendationTitle': recommendationTitle,
    'recommendation': recommendation,
  };

  static double _number(Object? value, {double fallback = 0}) =>
      value is num
          ? value.toDouble()
          : double.tryParse(value?.toString() ?? '') ?? fallback;
  static int? _integer(Object? value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
}
