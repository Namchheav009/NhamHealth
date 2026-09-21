package com.nhamhealth.nhamhealth_api.dto.response;

import java.math.BigDecimal;
import java.util.List;

/**
 * Clinical weight loss projection and AI-backed nutritional forecast
 * based on the user's biometric baseline and planned meals.
 */
public record WeightLossForecastResponse(
        BigDecimal currentWeightKg,
        BigDecimal targetWeightKg,
        BigDecimal projectedWeightLossKg,
        BigDecimal projectedEndWeightKg,
        BigDecimal bmrCalories,
        BigDecimal tdeeCalories,
        BigDecimal dailyPlannedCalories,
        BigDecimal dailyDeficitCalories,
        Integer timeframeDays,
        BigDecimal weeklyPaceKg,
        String paceStatus, // "STEADY", "OPTIMAL", "RAPID", "SURPLUS", "MAINTENANCE"
        String paceDescription,
        boolean calorieWarning,
        String calorieWarningMessage,
        List<ForecastRecommendationItem> recommendedFoods,
        List<ForecastRecommendationItem> recommendedBeverages,
        String aiAnalysisSummary,
        boolean hasPlannedMeals
) {}
