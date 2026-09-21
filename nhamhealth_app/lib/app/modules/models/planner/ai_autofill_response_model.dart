import 'meal_plan.dart';

/// Model representing an AI meal-plan response or its clinical fallback.
class AiAutoFillPlanResponse {
  final List<PlannedMeal> createdPlans;
  final int filledCount;
  final double dailyPlannedCalories;
  final double dailyDeficit;
  final double tdee;
  final double bmr;
  final double projectedWeeklyLossKg;
  final int timeframeDays;
  final double totalProjectedLossKg;
  final String aiRationale;
  final String goal;
  final String modelName;

  const AiAutoFillPlanResponse({
    required this.createdPlans,
    required this.filledCount,
    required this.dailyPlannedCalories,
    required this.dailyDeficit,
    required this.tdee,
    required this.bmr,
    required this.projectedWeeklyLossKg,
    required this.timeframeDays,
    required this.totalProjectedLossKg,
    required this.aiRationale,
    required this.goal,
    required this.modelName,
  });

  factory AiAutoFillPlanResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['createdPlans'] as List<dynamic>? ?? [];
    final plans =
        rawList
            .map(
              (e) => PlannedMeal.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();

    return AiAutoFillPlanResponse(
      createdPlans: plans,
      filledCount: (json['filledCount'] as num?)?.toInt() ?? plans.length,
      dailyPlannedCalories:
          (json['dailyPlannedCalories'] as num?)?.toDouble() ?? 0.0,
      dailyDeficit: (json['dailyDeficit'] as num?)?.toDouble() ?? 0.0,
      tdee: (json['tdee'] as num?)?.toDouble() ?? 0.0,
      bmr: (json['bmr'] as num?)?.toDouble() ?? 0.0,
      projectedWeeklyLossKg:
          (json['projectedWeeklyLossKg'] as num?)?.toDouble() ?? 0.0,
      timeframeDays: (json['timeframeDays'] as num?)?.toInt() ?? 28,
      totalProjectedLossKg:
          (json['totalProjectedLossKg'] as num?)?.toDouble() ?? 0.0,
      aiRationale: json['aiRationale'] as String? ?? '',
      goal: json['goal'] as String? ?? 'LOSE_WEIGHT',
      modelName: json['modelName'] as String? ?? 'Smart planner',
    );
  }
}
