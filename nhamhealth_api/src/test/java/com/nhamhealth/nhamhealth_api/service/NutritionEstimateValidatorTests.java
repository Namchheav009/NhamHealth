package com.nhamhealth.nhamhealth_api.service;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

import com.nhamhealth.nhamhealth_api.dto.response.AiFoodAnalysisResponse;

class NutritionEstimateValidatorTests {
    @Test
    void acceptsNutritionThatAgreesWithMacroEnergy() {
        assertTrue(NutritionEstimateValidator.isPlausible(food(430, 30, 45, 14, 8)));
    }

    @Test
    void rejectsCaloriesThatConflictWithMacros() {
        assertFalse(NutritionEstimateValidator.isPlausible(food(100, 40, 70, 30, 10)));
    }

    @Test
    void rejectsNegativeAndNonFiniteValues() {
        assertFalse(NutritionEstimateValidator.isPlausible(food(430, -1, 45, 14, 8)));
        assertFalse(NutritionEstimateValidator.isPlausible(food(Double.NaN, 30, 45, 14, 8)));
    }

    @Test
    void rejectsSugarThatExceedsTotalCarbohydrate() {
        assertFalse(NutritionEstimateValidator.isPlausible(food(250, 5, 20, 10, 40)));
    }

    private AiFoodAnalysisResponse food(
            double calories, double protein, double carbs, double fat, double sugar) {
        return new AiFoodAnalysisResponse(
                "Test meal", "Visible test meal", 0.85,
                calories, protein, carbs, fat, sugar,
                1, "plate", "Balance the meal", "Add vegetables.",
                false, 0, false, "AI_ESTIMATE", null, null);
    }
}
