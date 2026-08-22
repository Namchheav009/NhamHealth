package com.nhamhealth.nhamhealth_api.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.util.List;

import org.junit.jupiter.api.Test;

import com.nhamhealth.nhamhealth_api.dto.ai.FoodCandidate;
import com.nhamhealth.nhamhealth_api.dto.ai.FoodVisionComponent;
import com.nhamhealth.nhamhealth_api.dto.ai.FoodVisionResult;

class FoodVisionResultValidatorTests {
    private final FoodVisionResultValidator validator = new FoodVisionResultValidator();

    @Test
    void sortsDeduplicatesAndLimitsCandidates() {
        FoodVisionResult normalized = validator.validateAndNormalize(new FoodVisionResult(
                true, "", "Milk Tea", "Unknown", "drink",
                0.62, 0.70, 0.80,
                List.of(component("milk tea", 450, "milliliters")),
                List.of(
                        new FoodCandidate("Iced Latte", 0.14),
                        new FoodCandidate("Milk Tea", 0.62),
                        new FoodCandidate("Thai Tea", 0.24),
                        new FoodCandidate("milk tea", 0.60))));

        assertEquals(3, normalized.candidates().size());
        assertEquals("Milk Tea", normalized.candidates().getFirst().name());
        assertEquals("ml", normalized.components().getFirst().unit());
    }

    @Test
    void rejectsInvalidComponentAmount() {
        FoodVisionResult invalid = new FoodVisionResult(
                true, "", "Rice", "Unknown", "food",
                0.8, 0.8, 0.8,
                List.of(component("rice", 0, "g")),
                List.of(new FoodCandidate("Rice", 0.8)));

        assertThrows(IllegalArgumentException.class,
                () -> validator.validateAndNormalize(invalid));
    }

    @Test
    void normalizesNonFoodWithoutInventingNutritionComponents() {
        FoodVisionResult normalized = validator.validateAndNormalize(new FoodVisionResult(
                false, "Photo is too dark", null, null, null,
                0.9, 0.8, 0.7, null, null));

        assertFalse(normalized.foodDetected());
        assertEquals("Unknown food", normalized.mealName());
        assertEquals(0, normalized.mealConfidence());
        assertEquals(List.of(), normalized.components());
    }

    private FoodVisionComponent component(String name, double amount, String unit) {
        return new FoodVisionComponent(
                name, amount, unit, 0.8, 0.7,
                "visible", "visible food evidence");
    }
}
