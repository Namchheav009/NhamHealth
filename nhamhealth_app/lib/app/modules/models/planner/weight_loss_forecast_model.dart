import 'meal_plan.dart';

class ForecastRecommendationItem {
  const ForecastRecommendationItem({
    required this.itemType,
    required this.sourceId,
    required this.sourceTable,
    required this.name,
    required this.category,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.servingUnit,
    required this.servingSize,
    required this.imageUrl,
    required this.rationale,
    required this.ibmBadge,
  });

  final String itemType; // "FOOD" or "BEVERAGE"
  final int sourceId;
  final String sourceTable;
  final String name;
  final String category;
  final double calories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final String servingUnit;
  final double servingSize;
  final String imageUrl;
  final String rationale;
  final String ibmBadge;

  bool get isBeverage => itemType.toUpperCase() == 'BEVERAGE';
  bool get isFood => !isBeverage;

  factory ForecastRecommendationItem.fromJson(Map<String, dynamic> json) {
    return ForecastRecommendationItem(
      itemType: (json['itemType'] as String?) ?? 'FOOD',
      sourceId: (json['sourceId'] as num?)?.toInt() ?? 0,
      sourceTable: (json['sourceTable'] as String?) ?? 'planner_meals',
      name: (json['name'] as String?) ?? '',
      category: (json['category'] as String?) ?? '',
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      proteinGrams: (json['proteinGrams'] as num?)?.toDouble() ?? 0.0,
      carbsGrams: (json['carbsGrams'] as num?)?.toDouble() ?? 0.0,
      fatGrams: (json['fatGrams'] as num?)?.toDouble() ?? 0.0,
      servingUnit: (json['servingUnit'] as String?) ?? 'serving',
      servingSize: (json['servingSize'] as num?)?.toDouble() ?? 1.0,
      imageUrl: (json['imageUrl'] as String?) ?? '',
      rationale: (json['rationale'] as String?) ?? '',
      ibmBadge: (json['ibmBadge'] as String?) ?? 'Smart planner',
    );
  }

  Map<String, dynamic> toJson() => {
    'itemType': itemType,
    'sourceId': sourceId,
    'sourceTable': sourceTable,
    'name': name,
    'category': category,
    'calories': calories,
    'proteinGrams': proteinGrams,
    'carbsGrams': carbsGrams,
    'fatGrams': fatGrams,
    'servingUnit': servingUnit,
    'servingSize': servingSize,
    'imageUrl': imageUrl,
    'rationale': rationale,
    'ibmBadge': ibmBadge,
  };

  /// Converts this recommendation into a PlannedMeal candidate so it can be added directly to the plan
  PlannedMeal toPlannedMeal({MealPlanSlot slot = MealPlanSlot.lunch}) {
    return PlannedMeal(
      id: sourceId,
      name: name,
      slot: slot,
      calories: calories.round(),
      proteinGrams: proteinGrams,
      carbsGrams: carbsGrams,
      fatGrams: fatGrams,
      category: category,
      imageUrl: imageUrl,
      recommendationNote: rationale,
      ingredients: const [],
    );
  }
}

class WeightLossForecast {
  const WeightLossForecast({
    required this.currentWeightKg,
    this.age,
    this.heightCm,
    this.bmi,
    this.projectedBmi,
    this.healthyWeightMinKg,
    this.healthyWeightMaxKg,
    this.bmiStatus = 'UNKNOWN',
    this.recommendedWeightDirection = 'UNKNOWN',
    this.activityLevel = 'UNKNOWN',
    this.hasBiometricProfile = false,
    this.energyEstimateUsesDefaults = false,
    required this.targetWeightKg,
    required this.projectedWeightLossKg,
    required this.projectedEndWeightKg,
    required this.bmrCalories,
    required this.tdeeCalories,
    required this.dailyPlannedCalories,
    required this.dailyDeficitCalories,
    required this.timeframeDays,
    required this.weeklyPaceKg,
    required this.paceStatus,
    required this.paceDescription,
    required this.calorieWarning,
    required this.calorieWarningMessage,
    required this.recommendedFoods,
    required this.recommendedBeverages,
    required this.aiAnalysisSummary,
    this.hasPlannedMeals = false,
  });

  final double currentWeightKg;
  final int? age;
  final double? heightCm;
  final double? bmi;
  final double? projectedBmi;
  final double? healthyWeightMinKg;
  final double? healthyWeightMaxKg;
  final String bmiStatus;
  final String recommendedWeightDirection;
  final String activityLevel;
  final bool hasBiometricProfile;
  final bool energyEstimateUsesDefaults;
  final double targetWeightKg;
  final double projectedWeightLossKg;
  final double projectedEndWeightKg;
  final double bmrCalories;
  final double tdeeCalories;
  final double dailyPlannedCalories;
  final double dailyDeficitCalories;
  final int timeframeDays;
  final double weeklyPaceKg;
  final String
  paceStatus; // "STEADY", "OPTIMAL", "RAPID", "SURPLUS", "MAINTENANCE"
  final String paceDescription;
  final bool calorieWarning;
  final String calorieWarningMessage;
  final List<ForecastRecommendationItem> recommendedFoods;
  final List<ForecastRecommendationItem> recommendedBeverages;
  final String aiAnalysisSummary;
  final bool hasPlannedMeals;

  bool get isSurplus => dailyDeficitCalories <= 0 || paceStatus == 'SURPLUS';
  bool get isOptimal => paceStatus == 'OPTIMAL';
  bool get isRapid => paceStatus == 'RAPID';
  bool get hasBmiContext => hasBiometricProfile && bmi != null;

  double? get resolvedProjectedBmi {
    if (projectedBmi != null) return projectedBmi;
    final height = heightCm;
    if (height == null || height <= 0) return null;
    final heightMeters = height / 100;
    return projectedEndWeightKg / (heightMeters * heightMeters);
  }

  double? get resolvedHealthyWeightMinKg {
    if (healthyWeightMinKg != null) return healthyWeightMinKg;
    final height = heightCm;
    if (height == null || height <= 0) return null;
    final heightMeters = height / 100;
    return 18.5 * heightMeters * heightMeters;
  }

  double? get resolvedHealthyWeightMaxKg {
    if (healthyWeightMaxKg != null) return healthyWeightMaxKg;
    final height = heightCm;
    if (height == null || height <= 0) return null;
    final heightMeters = height / 100;
    return 24.9 * heightMeters * heightMeters;
  }

  bool get projectionBelowHealthyRange {
    final value = resolvedProjectedBmi;
    return value != null && value < 18.5;
  }

  String get resolvedWeightDirection {
    final direction = recommendedWeightDirection.toUpperCase();
    if (direction == 'GAIN' || direction == 'MAINTAIN' || direction == 'LOSE') {
      return direction;
    }
    final value = bmi;
    if (value == null) return 'LOSE';
    if (value < 18.5) return 'GAIN';
    if (value < 25) return 'MAINTAIN';
    return 'LOSE';
  }

  bool get shouldGainWeight => resolvedWeightDirection == 'GAIN';
  bool get shouldMaintainWeight => resolvedWeightDirection == 'MAINTAIN';
  bool get shouldLoseWeight => resolvedWeightDirection == 'LOSE';

  String get weightDirectionTitleKey => switch (resolvedWeightDirection) {
    'GAIN' => 'planner.weight_direction_gain',
    'MAINTAIN' => 'planner.weight_direction_maintain',
    'LOSE' => 'planner.weight_direction_lose',
    _ => 'planner.weight_direction_unknown',
  };

  String get weightDirectionMessageKey => switch (resolvedWeightDirection) {
    'GAIN' => 'planner.weight_direction_gain_help',
    'MAINTAIN' => 'planner.weight_direction_maintain_help',
    'LOSE' => 'planner.weight_direction_lose_help',
    _ => 'planner.weight_direction_unknown_help',
  };

  String get bmiStatusKey => switch (bmiStatus.toUpperCase()) {
    'UNDER_18' => 'profile.bmi_under_18',
    'UNDERWEIGHT' => 'profile.bmi_underweight_range',
    'HEALTHY' => 'profile.bmi_healthy_range',
    'OVERWEIGHT' => 'profile.bmi_overweight_range',
    'OBESITY' => 'profile.bmi_obesity_range',
    _ => 'profile.not_set',
  };

  String get activityLevelKey => switch (activityLevel.toUpperCase()) {
    'SEDENTARY' => 'planner.activity_sedentary',
    'LIGHT' || 'LIGHTLY_ACTIVE' => 'planner.activity_light',
    'ACTIVE' || 'VERY_ACTIVE' => 'planner.activity_active',
    'EXTRA_ACTIVE' || 'EXTREMELY_ACTIVE' => 'planner.activity_very_active',
    'MODERATE' || 'MODERATELY_ACTIVE' => 'planner.activity_moderate',
    'MODERATE_ESTIMATE' => 'planner.activity_moderate_estimated',
    _ => 'planner.activity_unknown',
  };

  String get paceStatusKey => switch (paceStatus.toUpperCase()) {
    'OPTIMAL' => 'planner.pace_optimal',
    'STEADY' => 'planner.pace_steady',
    'RAPID' => 'planner.pace_rapid',
    'SURPLUS' => 'planner.pace_surplus',
    _ => 'planner.pace_balanced',
  };

  Map<String, dynamic> toJson() => {
    'currentWeightKg': currentWeightKg,
    'age': age,
    'heightCm': heightCm,
    'bmi': bmi,
    'projectedBmi': projectedBmi,
    'healthyWeightMinKg': healthyWeightMinKg,
    'healthyWeightMaxKg': healthyWeightMaxKg,
    'bmiStatus': bmiStatus,
    'recommendedWeightDirection': recommendedWeightDirection,
    'activityLevel': activityLevel,
    'hasBiometricProfile': hasBiometricProfile,
    'energyEstimateUsesDefaults': energyEstimateUsesDefaults,
    'targetWeightKg': targetWeightKg,
    'projectedWeightLossKg': projectedWeightLossKg,
    'projectedEndWeightKg': projectedEndWeightKg,
    'bmrCalories': bmrCalories,
    'tdeeCalories': tdeeCalories,
    'dailyPlannedCalories': dailyPlannedCalories,
    'dailyDeficitCalories': dailyDeficitCalories,
    'timeframeDays': timeframeDays,
    'weeklyPaceKg': weeklyPaceKg,
    'paceStatus': paceStatus,
    'paceDescription': paceDescription,
    'calorieWarning': calorieWarning,
    'calorieWarningMessage': calorieWarningMessage,
    'recommendedFoods': recommendedFoods.map((e) => e.toJson()).toList(),
    'recommendedBeverages':
        recommendedBeverages.map((e) => e.toJson()).toList(),
    'aiAnalysisSummary': aiAnalysisSummary,
    'hasPlannedMeals': hasPlannedMeals,
  };

  factory WeightLossForecast.fromJson(Map<String, dynamic> json) {
    final rawFoods = json['recommendedFoods'];
    final foods =
        (rawFoods is List)
            ? rawFoods
                .map(
                  (e) => ForecastRecommendationItem.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ),
                )
                .toList()
            : <ForecastRecommendationItem>[];

    final rawDrinks = json['recommendedBeverages'];
    final drinks =
        (rawDrinks is List)
            ? rawDrinks
                .map(
                  (e) => ForecastRecommendationItem.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ),
                )
                .toList()
            : <ForecastRecommendationItem>[];

    return WeightLossForecast(
      currentWeightKg: (json['currentWeightKg'] as num?)?.toDouble() ?? 70.0,
      age: (json['age'] as num?)?.toInt(),
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      bmi: (json['bmi'] as num?)?.toDouble(),
      projectedBmi: (json['projectedBmi'] as num?)?.toDouble(),
      healthyWeightMinKg: (json['healthyWeightMinKg'] as num?)?.toDouble(),
      healthyWeightMaxKg: (json['healthyWeightMaxKg'] as num?)?.toDouble(),
      bmiStatus: (json['bmiStatus'] as String?) ?? 'UNKNOWN',
      recommendedWeightDirection:
          (json['recommendedWeightDirection'] as String?) ?? 'UNKNOWN',
      activityLevel: (json['activityLevel'] as String?) ?? 'UNKNOWN',
      hasBiometricProfile: json['hasBiometricProfile'] == true,
      energyEstimateUsesDefaults: json['energyEstimateUsesDefaults'] == true,
      targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble() ?? 67.0,
      projectedWeightLossKg:
          (json['projectedWeightLossKg'] as num?)?.toDouble() ?? 0.0,
      projectedEndWeightKg:
          (json['projectedEndWeightKg'] as num?)?.toDouble() ?? 70.0,
      bmrCalories: (json['bmrCalories'] as num?)?.toDouble() ?? 1600.0,
      tdeeCalories: (json['tdeeCalories'] as num?)?.toDouble() ?? 2400.0,
      dailyPlannedCalories:
          (json['dailyPlannedCalories'] as num?)?.toDouble() ?? 1900.0,
      dailyDeficitCalories:
          (json['dailyDeficitCalories'] as num?)?.toDouble() ?? 500.0,
      timeframeDays: (json['timeframeDays'] as num?)?.toInt() ?? 28,
      weeklyPaceKg: (json['weeklyPaceKg'] as num?)?.toDouble() ?? 0.45,
      paceStatus: (json['paceStatus'] as String?) ?? 'OPTIMAL',
      paceDescription: (json['paceDescription'] as String?) ?? '',
      calorieWarning: json['calorieWarning'] == true,
      calorieWarningMessage: (json['calorieWarningMessage'] as String?) ?? '',
      recommendedFoods: foods,
      recommendedBeverages: drinks,
      aiAnalysisSummary: (json['aiAnalysisSummary'] as String?) ?? '',
      hasPlannedMeals: json['hasPlannedMeals'] == true,
    );
  }

  factory WeightLossForecast.fallback({
    double currentWeightKg = 70.0,
    int? age,
    double? heightCm,
    double? bmi,
    double? projectedBmi,
    double? healthyWeightMinKg,
    double? healthyWeightMaxKg,
    String bmiStatus = 'UNKNOWN',
    String recommendedWeightDirection = 'UNKNOWN',
    String activityLevel = 'UNKNOWN',
    bool hasBiometricProfile = false,
    bool energyEstimateUsesDefaults = false,
    int timeframeDays = 28,
    double dailyDeficit = 500.0,
    MealPlannerHealthGoal goal = MealPlannerHealthGoal.loseWeight,
    bool hasPlannedMeals = false,
  }) {
    final isWeightLoss = goal == MealPlannerHealthGoal.loseWeight;
    final effectiveDeficit = isWeightLoss ? dailyDeficit : 0.0;
    final loss = (effectiveDeficit * timeframeDays) / 7700.0;
    final pace = (effectiveDeficit * 7.0) / 7700.0;
    return WeightLossForecast(
      currentWeightKg: currentWeightKg,
      age: age,
      heightCm: heightCm,
      bmi: bmi,
      projectedBmi: projectedBmi,
      healthyWeightMinKg: healthyWeightMinKg,
      healthyWeightMaxKg: healthyWeightMaxKg,
      bmiStatus: bmiStatus,
      recommendedWeightDirection: recommendedWeightDirection,
      activityLevel: activityLevel,
      hasBiometricProfile: hasBiometricProfile,
      energyEstimateUsesDefaults: energyEstimateUsesDefaults,
      targetWeightKg:
          isWeightLoss
              ? (currentWeightKg - 3.0).clamp(35.0, 300.0)
              : currentWeightKg,
      projectedWeightLossKg: double.parse(loss.toStringAsFixed(2)),
      projectedEndWeightKg: double.parse(
        (currentWeightKg - loss).toStringAsFixed(1),
      ),
      bmrCalories: 1650.0,
      tdeeCalories: 2450.0,
      dailyPlannedCalories: isWeightLoss ? 1950.0 : 2450.0,
      dailyDeficitCalories: effectiveDeficit,
      timeframeDays: timeframeDays,
      weeklyPaceKg: double.parse(pace.toStringAsFixed(2)),
      paceStatus: isWeightLoss ? 'OPTIMAL' : 'BALANCED',
      paceDescription:
          isWeightLoss
              ? 'A moderate calorie target that prioritizes protein and variety.'
              : 'Energy intake is aligned with maintenance needs for stable weight.',
      calorieWarning: false,
      calorieWarningMessage: '',
      recommendedFoods: const [],
      recommendedBeverages: const [],
      aiAnalysisSummary:
          isWeightLoss
              ? 'Your planned meals support a moderate calorie deficit.'
              : 'Your planned meals support balanced energy and weight maintenance.',
      hasPlannedMeals: hasPlannedMeals,
    );
  }
}
