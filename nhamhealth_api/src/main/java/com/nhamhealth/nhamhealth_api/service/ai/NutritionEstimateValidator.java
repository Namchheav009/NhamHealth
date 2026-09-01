package com.nhamhealth.nhamhealth_api.service.ai;

import com.nhamhealth.nhamhealth_api.dto.response.AiFoodAnalysisResponse;

/** Deterministic safety checks for nutrition values returned by a language model. */
final class NutritionEstimateValidator {
    private static final double MAX_ENERGY_DIFFERENCE_RATIO = 0.45;

    private NutritionEstimateValidator() {}

    static boolean isPlausible(AiFoodAnalysisResponse value) {
        if (value == null || value.name() == null || value.name().isBlank()
                || value.name().length() > 150
                || !Double.isFinite(value.confidence())
                || value.confidence() < 0 || value.confidence() > 1
                || !finiteAndNonNegative(
                value.calories(), value.protein(), value.carbs(), value.fat(), value.sugar())) {
            return false;
        }
        if (!Double.isFinite(value.servingSize()) || value.servingSize() <= 0
                || value.servingSize() > 100_000) return false;
        if (value.servingUnit() == null || value.servingUnit().isBlank()
                || value.servingUnit().length() > 40) return false;
        if (value.calories() < 10 || value.calories() > 5_000) return false;
        if (value.protein() > 500 || value.carbs() > 500 || value.fat() > 300 || value.sugar() > 300) {
            return false;
        }
        if (value.sugar() > value.carbs() * 1.10 + 2) return false;

        double caloriesFromMacros = value.protein() * 4 + value.carbs() * 4 + value.fat() * 9;
        double differenceRatio = Math.abs(caloriesFromMacros - value.calories()) / value.calories();
        return differenceRatio <= MAX_ENERGY_DIFFERENCE_RATIO;
    }

    /**
     * Repairs only deterministic formatting/consistency defects in an otherwise
     * usable estimate. It never invents macros when the model supplied no energy
     * evidence, and repaired estimates are deliberately marked low-confidence.
     */
    static AiFoodAnalysisResponse normalize(AiFoodAnalysisResponse value) {
        if (value == null || value.name() == null || value.name().isBlank()
                || value.name().length() > 150) return null;
        if (!finiteWithin(value.protein(), 500)
                || !finiteWithin(value.carbs(), 500)
                || !finiteWithin(value.fat(), 300)
                || !finiteWithin(value.sugar(), 300)) return null;

        double protein = value.protein();
        double carbs = value.carbs();
        double fat = value.fat();
        double sugar = Math.min(value.sugar(), carbs);
        double macroCalories = protein * 4 + carbs * 4 + fat * 9;
        if (macroCalories < 10 || macroCalories > 5_000) return null;

        double calories = value.calories();
        if (!Double.isFinite(calories) || calories < 10 || calories > 5_000
                || Math.abs(macroCalories - calories) / calories > MAX_ENERGY_DIFFERENCE_RATIO) {
            calories = roundOneDecimal(macroCalories);
        }
        double servingSize = Double.isFinite(value.servingSize())
                && value.servingSize() > 0 && value.servingSize() <= 100_000
                ? value.servingSize() : 1;
        String servingUnit = value.servingUnit() == null || value.servingUnit().isBlank()
                || value.servingUnit().length() > 40 ? "serving" : value.servingUnit().trim();
        String recommendationTitle = value.recommendationTitle() == null
                || value.recommendationTitle().isBlank()
                ? "Review this estimate" : value.recommendationTitle().trim();
        String recommendation = value.recommendation() == null
                || value.recommendation().isBlank()
                ? "Confirm the food and portion before saving." : value.recommendation().trim();
        String analysis = value.analysis() == null || value.analysis().isBlank()
                ? "The food was recognized, but its nutrition values required consistency correction."
                : value.analysis().trim();
        double confidence = Double.isFinite(value.confidence())
                ? Math.min(Math.clamp(value.confidence(), 0, 1), 0.59) : 0;

        AiFoodAnalysisResponse normalized = new AiFoodAnalysisResponse(
                value.analysisId(), value.name().trim(), analysis, confidence,
                calories, protein, carbs, fat, sugar, servingSize, servingUnit,
                recommendationTitle, recommendation, value.databaseMatched(),
                value.databaseMatchConfidence(), true, value.dataSource(),
                value.disclaimer(), value.privacyNotice());
        return isPlausible(normalized) ? normalized : null;
    }

    private static boolean finiteWithin(double value, double maximum) {
        return Double.isFinite(value) && value >= 0 && value <= maximum;
    }

    private static double roundOneDecimal(double value) {
        return Math.round(value * 10) / 10.0;
    }

    private static boolean finiteAndNonNegative(double... values) {
        for (double value : values) {
            if (!Double.isFinite(value) || value < 0) return false;
        }
        return true;
    }
}
