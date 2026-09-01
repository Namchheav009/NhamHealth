package com.nhamhealth.nhamhealth_api.service.ai;

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
        assertEquals("drink", normalized.components().getFirst().componentType());
        assertEquals(450, normalized.components().getFirst().liquidVolumeMl());
        assertEquals("other", normalized.components().getFirst().beverageType());
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
    void rejectsDuplicateComponentsThatCouldDoubleCountNutrition() {
        FoodVisionResult invalid = new FoodVisionResult(
                true, "", "Rice bowl", "Unknown", "food",
                0.8, 0.8, 0.8,
                List.of(component("Rice", 150, "g"), component("rice", 100, "g")),
                List.of(new FoodCandidate("Rice bowl", 0.8)));

        assertThrows(IllegalArgumentException.class,
                () -> validator.validateAndNormalize(invalid));
    }

    @Test
    void rejectsMealNameThatDisagreesWithTopCandidate() {
        FoodVisionResult invalid = new FoodVisionResult(
                true, "", "Milk Tea", "Unknown", "drink",
                0.55, 0.8, 0.8,
                List.of(component("Milk Tea", 350, "ml")),
                List.of(
                        new FoodCandidate("Iced Latte", 0.8),
                        new FoodCandidate("Milk Tea", 0.55)));

        assertThrows(IllegalArgumentException.class,
                () -> validator.validateAndNormalize(invalid));
    }

    @Test
    void acceptsMixedFoodAndDrinkAndUsesTheCandidateConfidence() {
        FoodVisionResult normalized = validator.validateAndNormalize(new FoodVisionResult(
                true, "", "Chicken rice with iced tea", "Unknown", "food and drink",
                0.81, 0.72, 0.76,
                List.of(
                        component("Chicken rice", 320, "g"),
                        component("Iced tea", 300, "ml")),
                List.of(new FoodCandidate("Chicken rice with iced tea", 0.83))));

        assertEquals("mixed", normalized.type());
        assertEquals(0.83, normalized.mealConfidence());
        assertEquals("ml", normalized.components().get(1).unit());
        assertEquals("food", normalized.components().get(0).componentType());
        assertEquals("drink", normalized.components().get(1).componentType());
        assertEquals(300, normalized.components().get(1).liquidVolumeMl());
    }

    @Test
    void preservesStructuredPlainWaterDetails() {
        FoodVisionComponent water = new FoodVisionComponent(
                "Mineral water", 0.5, "l", 0.94, 0.82,
                "unknown", "label identifies mineral water",
                "drink", 470, "plain_water");
        FoodVisionResult normalized = validator.validateAndNormalize(new FoodVisionResult(
                true, "", "Mineral water", "Unknown", "drink",
                0.94, 0.82, 0.2, List.of(water),
                List.of(new FoodCandidate("Mineral water", 0.94))));

        assertEquals("drink", normalized.components().getFirst().componentType());
        assertEquals(470, normalized.components().getFirst().liquidVolumeMl());
        assertEquals("plain_water", normalized.components().getFirst().beverageType());
    }

    @Test
    void rejectsMealConfidenceThatDisagreesWithTopCandidate() {
        FoodVisionResult invalid = new FoodVisionResult(
                true, "", "Milk Tea", "Unknown", "drink",
                0.45, 0.8, 0.8,
                List.of(component("Milk Tea", 350, "ml")),
                List.of(new FoodCandidate("Milk Tea", 0.85)));

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
