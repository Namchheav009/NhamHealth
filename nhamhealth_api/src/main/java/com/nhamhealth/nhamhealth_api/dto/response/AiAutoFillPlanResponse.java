package com.nhamhealth.nhamhealth_api.dto.response;

import java.util.List;

/**
 * Response returned after IBM watsonx Granite AI auto-fills and balances a
 * weekly meal plan.
 */
public record AiAutoFillPlanResponse(
                List<MealPlanResponse> createdPlans,
                int filledCount,
                double dailyPlannedCalories,
                double dailyDeficit,
                double tdee,
                double bmr,
                double projectedWeeklyLossKg,
                int timeframeDays,
                double totalProjectedLossKg,
                String aiRationale,
                String goal,
                String modelName) {
}
