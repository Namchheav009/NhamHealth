class FoodCandidateModel {
  const FoodCandidateModel({required this.name, required this.confidence});

  final String name;
  final double confidence;

  factory FoodCandidateModel.fromJson(Map<String, dynamic> json) =>
      FoodCandidateModel(
        name: json['name']?.toString().trim() ?? '',
        confidence: _number(json['confidence']),
      );

  Map<String, dynamic> toJson() => {'name': name, 'confidence': confidence};
}

class DetectedFoodComponentModel {
  const DetectedFoodComponentModel({
    required this.name,
    required this.estimatedAmount,
    required this.unit,
    required this.confidence,
    required this.portionConfidence,
    required this.preparationMethod,
    required this.visibleEvidence,
    required this.databaseMatched,
    this.matchedFoodId,
    this.matchedFoodName,
    required this.databaseMatchConfidence,
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    required this.sugar,
    required this.fiber,
    required this.sodium,
    required this.nutritionSource,
    required this.requiresUserConfirmation,
  });

  final String name;
  final double estimatedAmount;
  final String unit;
  final double confidence;
  final double portionConfidence;
  final String preparationMethod;
  final String visibleEvidence;
  final bool databaseMatched;
  final int? matchedFoodId;
  final String? matchedFoodName;
  final double databaseMatchConfidence;
  final double calories;
  final double protein;
  final double carbohydrates;
  final double fat;
  final double sugar;
  final double fiber;
  final double sodium;
  final String nutritionSource;
  final bool requiresUserConfirmation;

  factory DetectedFoodComponentModel.fromJson(Map<String, dynamic> json) =>
      DetectedFoodComponentModel(
        name: json['name']?.toString().trim() ?? 'Unknown component',
        estimatedAmount: _number(json['estimatedAmount']),
        unit: json['unit']?.toString() ?? 'serving',
        confidence: _number(json['confidence']),
        portionConfidence: _number(json['portionConfidence']),
        preparationMethod: json['preparationMethod']?.toString() ?? 'unknown',
        visibleEvidence: json['visibleEvidence']?.toString() ?? '',
        databaseMatched: json['databaseMatched'] == true,
        matchedFoodId: _integer(json['matchedFoodId']),
        matchedFoodName: json['matchedFoodName']?.toString(),
        databaseMatchConfidence: _number(json['databaseMatchConfidence']),
        calories: _number(json['calories']),
        protein: _number(json['protein']),
        carbohydrates: _number(json['carbohydrates']),
        fat: _number(json['fat']),
        sugar: _number(json['sugar']),
        fiber: _number(json['fiber']),
        sodium: _number(json['sodium']),
        nutritionSource: json['nutritionSource']?.toString() ?? 'UNAVAILABLE',
        requiresUserConfirmation: json['requiresUserConfirmation'] == true,
      );

  Map<String, dynamic> toJson() => {
    'name': name,
    'estimatedAmount': estimatedAmount,
    'unit': unit,
    'confidence': confidence,
    'portionConfidence': portionConfidence,
    'preparationMethod': preparationMethod,
    'visibleEvidence': visibleEvidence,
    'databaseMatched': databaseMatched,
    'matchedFoodId': matchedFoodId,
    'matchedFoodName': matchedFoodName,
    'databaseMatchConfidence': databaseMatchConfidence,
    'calories': calories,
    'protein': protein,
    'carbohydrates': carbohydrates,
    'fat': fat,
    'sugar': sugar,
    'fiber': fiber,
    'sodium': sodium,
    'nutritionSource': nutritionSource,
    'requiresUserConfirmation': requiresUserConfirmation,
  };
}

class NutritionSummaryModel {
  const NutritionSummaryModel({
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    required this.sugar,
    required this.fiber,
    required this.sodium,
    required this.source,
    required this.complete,
  });

  final double calories;
  final double protein;
  final double carbohydrates;
  final double fat;
  final double sugar;
  final double fiber;
  final double sodium;
  final String source;
  final bool complete;

  factory NutritionSummaryModel.fromJson(Map<String, dynamic> json) =>
      NutritionSummaryModel(
        calories: _number(json['calories']),
        protein: _number(json['protein']),
        carbohydrates: _number(json['carbohydrates']),
        fat: _number(json['fat']),
        sugar: _number(json['sugar']),
        fiber: _number(json['fiber']),
        sodium: _number(json['sodium']),
        source: json['source']?.toString() ?? 'UNAVAILABLE',
        complete: json['complete'] == true,
      );

  Map<String, dynamic> toJson() => {
    'calories': calories,
    'protein': protein,
    'carbohydrates': carbohydrates,
    'fat': fat,
    'sugar': sugar,
    'fiber': fiber,
    'sodium': sodium,
    'source': source,
    'complete': complete,
  };
}

double _number(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

int? _integer(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value');
