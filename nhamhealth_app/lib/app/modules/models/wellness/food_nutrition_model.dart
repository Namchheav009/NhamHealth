import 'food_analysis_model.dart';

class FoodNutritionModel {
  final int? id;
  final int? analysisId;
  final String name;
  final String analysis;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double sugar;
  final double fiber;
  final double sodium;
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
  final bool foodDetected;
  final String reason;
  final String mealName;
  final String cuisine;
  final String mealType;
  final bool requiresDrinkDetails;
  final double mealIdentityConfidence;
  final double portionConfidence;
  final double preparationConfidence;
  final List<DetectedFoodComponentModel> components;
  final List<FoodCandidateModel> candidates;
  final bool nutritionComplete;

  const FoodNutritionModel({
    this.id,
    this.analysisId,
    required this.name,
    this.analysis = '',
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.sugar,
    this.fiber = 0,
    this.sodium = 0,
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
    this.foodDetected = true,
    this.reason = '',
    String? mealName,
    this.cuisine = 'Unknown',
    this.mealType = 'food',
    this.requiresDrinkDetails = false,
    double? mealIdentityConfidence,
    this.portionConfidence = 0,
    this.preparationConfidence = 0,
    this.components = const [],
    this.candidates = const [],
    this.nutritionComplete = true,
  }) : mealName = mealName ?? name,
       mealIdentityConfidence = mealIdentityConfidence ?? confidence;

  factory FoodNutritionModel.fromJson(Map<String, dynamic> json) {
    final nutrition =
        json['nutrition'] is Map
            ? Map<String, dynamic>.from(json['nutrition'] as Map)
            : const <String, dynamic>{};
    final mealName =
        json['mealName']?.toString().trim() ??
        json['name']?.toString().trim() ??
        '';
    final mealConfidence = _number(
      json['mealIdentityConfidence'],
      fallback: _number(json['confidence']),
    );
    return FoodNutritionModel(
      id: _integer(json['id']),
      analysisId: _integer(json['analysisId']),
      name: _foodName(json['name'] ?? json['mealName']),
      analysis: json['analysis']?.toString() ?? '',
      calories: _number(
        json['calories'],
        fallback: _number(nutrition['calories']),
      ),
      protein: _number(
        json['protein'],
        fallback: _number(nutrition['protein']),
      ),
      carbs: _number(
        json['carbs'],
        fallback: _number(nutrition['carbohydrates']),
      ),
      fat: _number(json['fat'], fallback: _number(nutrition['fat'])),
      sugar: _number(json['sugar'], fallback: _number(nutrition['sugar'])),
      fiber: _number(json['fiber'], fallback: _number(nutrition['fiber'])),
      sodium: _number(json['sodium'], fallback: _number(nutrition['sodium'])),
      servingSize: _number(json['servingSize'], fallback: 1),
      servingUnit: json['servingUnit']?.toString() ?? 'serving',
      confidence: mealConfidence,
      recommendationTitle:
          json['recommendationTitle']?.toString() ?? 'AI Recommendation',
      recommendation: json['recommendation']?.toString() ?? '',
      databaseMatched: json['databaseMatched'] == true,
      databaseMatchConfidence: _number(json['databaseMatchConfidence']),
      needsUserConfirmation: json['needsUserConfirmation'] == true,
      dataSource:
          json['dataSource']?.toString() ??
          nutrition['source']?.toString() ??
          'AI_ESTIMATE',
      disclaimer: json['disclaimer']?.toString() ?? '',
      privacyNotice: json['privacyNotice']?.toString() ?? '',
      foodDetected: json['foodDetected'] != false,
      reason: json['reason']?.toString() ?? '',
      mealName: mealName.isEmpty ? 'Unknown food' : mealName,
      cuisine: json['cuisine']?.toString() ?? 'Unknown',
      mealType: json['type']?.toString() ?? 'food',
      requiresDrinkDetails: json['requiresDrinkDetails'] == true,
      mealIdentityConfidence: mealConfidence,
      portionConfidence: _number(json['portionConfidence']),
      preparationConfidence: _number(json['preparationConfidence']),
      components: _modelList(
        json['components'],
        DetectedFoodComponentModel.fromJson,
      ),
      candidates: _modelList(json['candidates'], FoodCandidateModel.fromJson),
      nutritionComplete:
          nutrition.isEmpty
              ? _number(json['calories']) > 0
              : nutrition['complete'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'analysisId': analysisId,
    'name': name,
    'analysis': analysis,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'sugar': sugar,
    'fiber': fiber,
    'sodium': sodium,
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
    'foodDetected': foodDetected,
    'reason': reason,
    'mealName': mealName,
    'cuisine': cuisine,
    'type': mealType,
    'requiresDrinkDetails': requiresDrinkDetails,
    'mealIdentityConfidence': mealIdentityConfidence,
    'portionConfidence': portionConfidence,
    'preparationConfidence': preparationConfidence,
    'components': components.map((item) => item.toJson()).toList(),
    'candidates': candidates.map((item) => item.toJson()).toList(),
    'nutrition': {
      'calories': calories,
      'protein': protein,
      'carbohydrates': carbs,
      'fat': fat,
      'sugar': sugar,
      'fiber': fiber,
      'sodium': sodium,
      'source': dataSource,
      'complete': nutritionComplete,
    },
  };

  FoodNutritionModel withServing({required double size, required String unit}) {
    final requestedUnit = unit.trim();
    final sameUnit =
        requestedUnit.toLowerCase() == servingUnit.trim().toLowerCase();
    final safeSize = size <= 0 || !sameUnit ? servingSize : size;
    final factor = servingSize > 0 ? safeSize / servingSize : 1.0;
    return FoodNutritionModel(
      id: id,
      analysisId: analysisId,
      name: name,
      analysis: analysis,
      calories: calories * factor,
      protein: protein * factor,
      carbs: carbs * factor,
      fat: fat * factor,
      sugar: sugar * factor,
      fiber: fiber * factor,
      sodium: sodium * factor,
      servingSize: safeSize,
      servingUnit: sameUnit ? requestedUnit : servingUnit,
      confidence: confidence,
      recommendationTitle: recommendationTitle,
      recommendation: recommendation,
      databaseMatched: databaseMatched,
      databaseMatchConfidence: databaseMatchConfidence,
      needsUserConfirmation: false,
      dataSource: dataSource,
      disclaimer: disclaimer,
      privacyNotice: privacyNotice,
      foodDetected: foodDetected,
      reason: reason,
      mealName: mealName,
      cuisine: cuisine,
      mealType: mealType,
      requiresDrinkDetails: requiresDrinkDetails,
      mealIdentityConfidence: mealIdentityConfidence,
      portionConfidence: portionConfidence,
      preparationConfidence: preparationConfidence,
      components: components,
      candidates: candidates,
      nutritionComplete: nutritionComplete,
    );
  }

  FoodNutritionModel withAnalysisId(int? value) => FoodNutritionModel(
    id: id,
    analysisId: value,
    name: name,
    analysis: analysis,
    calories: calories,
    protein: protein,
    carbs: carbs,
    fat: fat,
    sugar: sugar,
    fiber: fiber,
    sodium: sodium,
    servingSize: servingSize,
    servingUnit: servingUnit,
    confidence: confidence,
    recommendationTitle: recommendationTitle,
    recommendation: recommendation,
    databaseMatched: databaseMatched,
    databaseMatchConfidence: databaseMatchConfidence,
    needsUserConfirmation: needsUserConfirmation,
    dataSource: dataSource,
    disclaimer: disclaimer,
    privacyNotice: privacyNotice,
    foodDetected: foodDetected,
    reason: reason,
    mealName: mealName,
    cuisine: cuisine,
    mealType: mealType,
    requiresDrinkDetails: requiresDrinkDetails,
    mealIdentityConfidence: mealIdentityConfidence,
    portionConfidence: portionConfidence,
    preparationConfidence: preparationConfidence,
    components: components,
    candidates: candidates,
    nutritionComplete: nutritionComplete,
  );

  FoodNutritionModel asDatabaseVerified() => FoodNutritionModel(
    id: id,
    analysisId: analysisId,
    name: name,
    analysis: analysis,
    calories: calories,
    protein: protein,
    carbs: carbs,
    fat: fat,
    sugar: sugar,
    fiber: fiber,
    sodium: sodium,
    servingSize: servingSize,
    servingUnit: servingUnit,
    confidence: confidence,
    recommendationTitle: recommendationTitle,
    recommendation: recommendation,
    databaseMatched: true,
    databaseMatchConfidence: 1,
    needsUserConfirmation: needsUserConfirmation,
    dataSource: 'DATABASE_VERIFIED',
    disclaimer: disclaimer,
    privacyNotice: privacyNotice,
    foodDetected: foodDetected,
    reason: reason,
    mealName: mealName,
    cuisine: cuisine,
    mealType: mealType,
    requiresDrinkDetails: requiresDrinkDetails,
    mealIdentityConfidence: mealIdentityConfidence,
    portionConfidence: portionConfidence,
    preparationConfidence: preparationConfidence,
    components: components,
    candidates: candidates,
    nutritionComplete: true,
  );

  bool get hasCompleteNutrition =>
      nutritionComplete &&
      dataSource != 'UNAVAILABLE' &&
      dataSource != 'PARTIAL_DATABASE';

  bool get hasNutritionEstimate => dataSource != 'UNAVAILABLE';

  bool get isDatabaseCalculated => dataSource == 'DATABASE_CALCULATED';

  String get nutritionSourceLabel => switch (dataSource) {
    'DATABASE_CALCULATED' => 'Database calculated',
    'HYBRID_ESTIMATED' => 'Database + AI estimate',
    'AI_ESTIMATED' || 'AI_ESTIMATE' => 'AI estimate',
    'PARTIAL_DATABASE' => 'Partial nutrition',
    'USER_ENTERED' => 'User entered',
    'UNAVAILABLE' => 'Nutrition unavailable',
    _ => databaseMatched ? 'Database matched' : 'Nutrition estimate',
  };

  static double _number(Object? value, {double fallback = 0}) =>
      value is num
          ? value.toDouble()
          : double.tryParse(value?.toString() ?? '') ?? fallback;

  static String _foodName(Object? value) {
    final name = value?.toString().trim() ?? '';
    return name.isEmpty ? 'Unknown food' : name;
  }

  static int? _integer(Object? value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');

  static List<T> _modelList<T>(
    Object? value,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }
}
