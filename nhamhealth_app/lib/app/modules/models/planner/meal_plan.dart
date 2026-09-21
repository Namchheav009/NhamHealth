import 'package:flutter/material.dart';

enum MealPlanSlot { breakfast, lunch, dinner, snack }

enum MealPlanStatus { planned, eaten, skipped }

extension MealPlanSlotUi on MealPlanSlot {
  String get labelKey => switch (this) {
    MealPlanSlot.breakfast => 'planner.breakfast',
    MealPlanSlot.lunch => 'planner.lunch',
    MealPlanSlot.dinner => 'planner.dinner',
    MealPlanSlot.snack => 'planner.snack',
  };
  IconData get icon => switch (this) {
    MealPlanSlot.breakfast => Icons.wb_sunny_outlined,
    MealPlanSlot.lunch => Icons.restaurant_rounded,
    MealPlanSlot.dinner => Icons.nightlight_round,
    MealPlanSlot.snack => Icons.apple_rounded,
  };
}

class PlannerIngredient {
  const PlannerIngredient({
    required this.name,
    this.quantity = 0,
    this.unit = '',
  });
  final String name;
  final double quantity;
  final String unit;
  factory PlannerIngredient.fromJson(dynamic value) {
    if (value is String) return PlannerIngredient(name: value.trim());
    final json = Map<String, dynamic>.from(value as Map);
    return PlannerIngredient(
      name: '${json['name'] ?? ''}'.trim(),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unit: '${json['unit'] ?? ''}'.trim(),
    );
  }
}

class PlannedMeal {
  const PlannedMeal({
    required this.id,
    required this.name,
    required this.calories,
    required this.slot,
    required this.ingredients,
    this.ingredientDetails = const [],
    this.planId,
    this.planDate,
    this.servings = 1,
    this.status = MealPlanStatus.planned,
    this.completedAt,
    this.actualServings,
    this.proteinGrams = 0,
    this.carbsGrams = 0,
    this.fatGrams = 0,
    this.categoryId,
    this.categoryIds = const [],
    this.category = '',
    this.description = '',
    this.cookingTimeMinutes,
    this.difficulty = '',
    this.instructions = const [],
    this.tags = const [],
    this.recommendedWeekday,
    this.imageUrl = '',
    this.recommendationNote = '',
  });
  final int id;
  final int? planId;
  final DateTime? planDate;
  final String name;
  final int calories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final double servings;
  final MealPlanStatus status;
  final DateTime? completedAt;
  final double? actualServings;
  final int? categoryId;
  final List<int> categoryIds;
  final MealPlanSlot slot;
  final List<String> ingredients;
  final List<PlannerIngredient> ingredientDetails;
  final String category;
  final String description;
  final int? cookingTimeMinutes;
  final String difficulty;
  final List<String> instructions;
  final List<String> tags;
  final int? recommendedWeekday;
  final String imageUrl;
  final String recommendationNote;

  PlannedMeal copyWith({
    int? planId,
    DateTime? planDate,
    MealPlanSlot? slot,
    double? servings,
    MealPlanStatus? status,
    DateTime? completedAt,
    double? actualServings,
    bool clearCompletedAt = false,
    bool clearActualServings = false,
    List<int>? categoryIds,
  }) => PlannedMeal(
    id: id,
    planId: planId ?? this.planId,
    planDate: planDate ?? this.planDate,
    name: name,
    calories: calories,
    proteinGrams: proteinGrams,
    carbsGrams: carbsGrams,
    fatGrams: fatGrams,
    servings: servings ?? this.servings,
    status: status ?? this.status,
    completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    actualServings:
        clearActualServings ? null : (actualServings ?? this.actualServings),
    slot: slot ?? this.slot,
    ingredients: ingredients,
    ingredientDetails: ingredientDetails,
    category: category,
    categoryId: categoryId,
    categoryIds: categoryIds ?? this.categoryIds,
    description: description,
    cookingTimeMinutes: cookingTimeMinutes,
    difficulty: difficulty,
    instructions: instructions,
    tags: tags,
    recommendedWeekday: recommendedWeekday,
    imageUrl: imageUrl,
    recommendationNote: recommendationNote,
  );

  factory PlannedMeal.fromJson(Map<String, dynamic> json) {
    final slotName =
        '${json['mealType'] ?? json['mealSlot'] ?? ''}'.toLowerCase();
    final dayName = '${json['dayOfWeek'] ?? ''}'.toUpperCase();
    final details = (json['ingredients'] as List<dynamic>? ?? const [])
        .map(PlannerIngredient.fromJson)
        .where((item) => item.name.isNotEmpty)
        .toList(growable: false);
    return PlannedMeal(
      id:
          (json['plannerMealId'] as num?)?.toInt() ??
          (json['mealId'] as num?)?.toInt() ??
          (json['id'] as num?)?.toInt() ??
          0,
      planId: (json['planId'] as num?)?.toInt(),
      planDate: DateTime.tryParse('${json['planDate'] ?? ''}'),
      name: '${json['mealName'] ?? json['name'] ?? ''}'.trim(),
      calories: (json['calories'] as num?)?.round() ?? 0,
      proteinGrams: (json['proteinGrams'] as num?)?.toDouble() ?? 0,
      carbsGrams: (json['carbsGrams'] as num?)?.toDouble() ?? 0,
      fatGrams: (json['fatGrams'] as num?)?.toDouble() ?? 0,
      servings: (json['servings'] as num?)?.toDouble() ?? 1,
      status: MealPlanStatus.values.firstWhere(
        (status) =>
            status.name == '${json['status'] ?? 'PLANNED'}'.toLowerCase(),
        orElse: () => MealPlanStatus.planned,
      ),
      completedAt: DateTime.tryParse('${json['completedAt'] ?? ''}'),
      actualServings: (json['actualServings'] as num?)?.toDouble(),
      slot: MealPlanSlot.values.firstWhere(
        (slot) => slot.name == slotName,
        orElse: () => MealPlanSlot.snack,
      ),
      ingredients: details.map((item) => item.name).toList(growable: false),
      ingredientDetails: details,
      categoryId: (json['categoryId'] as num?)?.toInt(),
      categoryIds: (json['categoryIds'] as List<dynamic>? ?? const [])
          .map((e) => (e as num).toInt())
          .toList(growable: false),
      category: '${json['category'] ?? ''}'.trim(),
      description: '${json['description'] ?? ''}'.trim(),
      cookingTimeMinutes: (json['cookingTimeMinutes'] as num?)?.toInt(),
      difficulty: '${json['difficulty'] ?? ''}'.trim(),
      instructions:
          (json['instructions'] as List<dynamic>? ?? const [])
              .map((e) => '$e')
              .toList(),
      tags:
          (json['tags'] as List<dynamic>? ?? const [])
              .map((e) => '$e')
              .toList(),
      recommendedWeekday:
          const {
            'MONDAY': 1,
            'TUESDAY': 2,
            'WEDNESDAY': 3,
            'THURSDAY': 4,
            'FRIDAY': 5,
            'SATURDAY': 6,
            'SUNDAY': 7,
          }[dayName],
      imageUrl:
          '${json['imageUrl'] ?? json['mainImageUrl'] ?? json['image'] ?? json['thumbnail'] ?? json['photoUrl'] ?? ''}'
              .trim(),
      recommendationNote:
          '${json['note'] ?? json['recommendationNote'] ?? ''}'.trim(),
    );
  }
}

class PlannerMealCategory {
  const PlannerMealCategory({
    required this.id,
    required this.name,
    this.imageUrl = '',
  });

  final int id;
  final String name;
  final String imageUrl;
}

class GroceryItem {
  const GroceryItem({
    required this.name,
    required this.category,
    this.quantity = 0,
    this.unit = '',
    this.sourceMeals = const [],
  });
  final String name;
  final String category;
  final double quantity;
  final String unit;
  final List<String> sourceMeals;
  String get key => '${name.toLowerCase()}|${unit.toLowerCase()}';
  String get quantityLabel {
    if (quantity <= 0) return '';
    final value =
        quantity == quantity.roundToDouble()
            ? quantity.toInt().toString()
            : quantity.toStringAsFixed(1);
    return '$value${unit.isEmpty ? '' : ' $unit'}';
  }
}

enum MealPlannerHealthGoal {
  loseWeight,
  maintainHealth;

  String get apiValue => switch (this) {
    loseWeight => 'LOSE_WEIGHT',
    maintainHealth => 'MAINTAIN_HEALTH',
  };
}

enum MealPlannerDiet {
  balanced,
  vegetarian,
  vegan;

  String get apiValue => name.toUpperCase();
}

class MealPlannerDietaryPreferences {
  const MealPlannerDietaryPreferences({
    this.diet = MealPlannerDiet.balanced,
    this.allergens = const [],
    this.excludedIngredients = const [],
    this.medicalFlags = const [],
  });

  final MealPlannerDiet diet;
  final List<String> allergens;
  final List<String> excludedIngredients;
  final List<String> medicalFlags;

  Map<String, dynamic> toJson() => {
    'diet': diet.apiValue,
    'allergens': allergens,
    'excludedIngredients': excludedIngredients,
    'medicalFlags': medicalFlags,
  };

  factory MealPlannerDietaryPreferences.fromJson(Map<String, dynamic> json) {
    List<String> strings(String key) =>
        (json[key] as List<dynamic>? ?? const [])
            .map((value) => '$value'.trim())
            .where((value) => value.isNotEmpty)
            .toList(growable: false);
    final dietValue = '${json['diet'] ?? ''}'.toUpperCase();
    return MealPlannerDietaryPreferences(
      diet: MealPlannerDiet.values.firstWhere(
        (diet) => diet.apiValue == dietValue,
        orElse: () => MealPlannerDiet.balanced,
      ),
      allergens: strings('allergens'),
      excludedIngredients: strings('excludedIngredients'),
      medicalFlags: strings('medicalFlags'),
    );
  }
}
