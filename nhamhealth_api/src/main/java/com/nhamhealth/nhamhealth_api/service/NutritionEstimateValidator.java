package com.nhamhealth.nhamhealth_api.service;

import com.nhamhealth.nhamhealth_api.dto.response.AiFoodAnalysisResponse;

/** Deterministic safety checks for nutrition values returned by a language model. */
final class NutritionEstimateValidator {
    private static final double MAX_ENERGY_DIFFERENCE_RATIO = 0.45;

    private NutritionEstimateValidator() {}

    static boolean isPlausible(AiFoodAnalysisResponse value) {
        if (value == null || !finiteAndNonNegative(
                value.calories(), value.protein(), value.carbs(), value.fat(), value.sugar())) {
            return false;
        }
        if (!Double.isFinite(value.servingSize()) || value.servingSize() <= 0) return false;
        if (value.servingUnit() == null || value.servingUnit().isBlank()) return false;
        if (value.calories() < 10 || value.calories() > 5_000) return false;
        if (value.protein() > 500 || value.carbs() > 500 || value.fat() > 300 || value.sugar() > 300) {
            return false;
        }
        if (value.sugar() > value.carbs() * 1.10 + 2) return false;

        double caloriesFromMacros = value.protein() * 4 + value.carbs() * 4 + value.fat() * 9;
        double differenceRatio = Math.abs(caloriesFromMacros - value.calories()) / value.calories();
        return differenceRatio <= MAX_ENERGY_DIFFERENCE_RATIO;
    }

    private static boolean finiteAndNonNegative(double... values) {
        for (double value : values) {
            if (!Double.isFinite(value) || value < 0) return false;
        }
        return true;
    }
}
