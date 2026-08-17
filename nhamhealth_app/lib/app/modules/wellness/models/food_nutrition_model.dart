class FoodNutritionModel {
  final int? id;
  final String name;
  final String analysis;
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
  final bool databaseMatched;
  final double databaseMatchConfidence;
  final bool needsUserConfirmation;
  final String dataSource;
  final String disclaimer;
  final String privacyNotice;

  const FoodNutritionModel({
    this.id,
    required this.name,
    this.analysis = '',
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
    this.databaseMatched = false,
    this.databaseMatchConfidence = 0,
    this.needsUserConfirmation = false,
    this.dataSource = 'AI_ESTIMATE',
    this.disclaimer = '',
    this.privacyNotice = '',
  });

  factory FoodNutritionModel.fromJson(Map<String, dynamic> json) =>
      FoodNutritionModel(
        id: _integer(json['id']),
        name: json['name']?.toString() ?? 'Unknown food',
        analysis: json['analysis']?.toString() ?? '',
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
        databaseMatched: json['databaseMatched'] == true,
        databaseMatchConfidence: _number(json['databaseMatchConfidence']),
        needsUserConfirmation: json['needsUserConfirmation'] == true,
        dataSource: json['dataSource']?.toString() ?? 'AI_ESTIMATE',
        disclaimer: json['disclaimer']?.toString() ?? '',
        privacyNotice: json['privacyNotice']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'analysis': analysis,
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
    'databaseMatched': databaseMatched,
    'databaseMatchConfidence': databaseMatchConfidence,
    'needsUserConfirmation': needsUserConfirmation,
    'dataSource': dataSource,
    'disclaimer': disclaimer,
    'privacyNotice': privacyNotice,
  };

  static double _number(Object? value, {double fallback = 0}) =>
      value is num
          ? value.toDouble()
          : double.tryParse(value?.toString() ?? '') ?? fallback;
  static int? _integer(Object? value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
}
