package com.nhamhealth.nhamhealth_api.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.Test;

import com.nhamhealth.nhamhealth_api.dto.ai.FoodVisionComponent;
import com.nhamhealth.nhamhealth_api.dto.ai.FoodComponentNutritionEstimate;
import com.nhamhealth.nhamhealth_api.dto.response.NutritionSource;
import com.nhamhealth.nhamhealth_api.entity.FoodNutrition;
import com.nhamhealth.nhamhealth_api.service.FoodDatabaseMatchingService.MatchCandidate;

class FoodNutritionCalculationServiceTests {
    private final FoodNutritionCalculationService service =
            new FoodNutritionCalculationService();

    @Test
    void scalesAllNutrientsFromOneHundredGramDatabaseServing() {
        FoodNutrition rice = food(
                130, 2.7, 28, 0.3, 0.1, 0.4, 1,
                100, "g");
        var calculated = service.calculate(
                component("Cooked rice", 200, "g"),
                Optional.of(new MatchCandidate(rice, 0.94)));

        assertEquals(260, calculated.calories());
        assertEquals(5.4, calculated.protein());
        assertEquals(56, calculated.carbohydrates());
        assertEquals(0.6, calculated.fat());
        assertEquals(0.2, calculated.sugar());
        assertEquals(0.8, calculated.fiber());
        assertEquals(2, calculated.sodium());
        assertEquals(NutritionSource.DATABASE_CALCULATED, calculated.nutritionSource());
        assertFalse(calculated.requiresUserConfirmation());
    }

    @Test
    void doesNotInventMassConversionForPieceBasedFood() {
        FoodNutrition chicken = food(
                200, 25, 4, 9, 0, 0, 300,
                1, "piece");
        var calculated = service.calculate(
                component("Chicken", 130, "g"),
                Optional.of(new MatchCandidate(chicken, 0.90)));

        assertEquals(NutritionSource.UNAVAILABLE, calculated.nutritionSource());
        assertTrue(calculated.requiresUserConfirmation());
        assertEquals(0, calculated.calories());
    }

    @Test
    void marksAggregatePartialWhenAnyComponentCannotBeCalculated() {
        FoodNutrition rice = food(
                130, 2.7, 28, 0.3, 0.1, 0.4, 1,
                100, "g");
        var matched = service.calculate(
                component("Rice", 100, "g"),
                Optional.of(new MatchCandidate(rice, 1)));
        var unmatched = service.calculate(
                component("Unknown sauce", 20, "g"), Optional.empty());

        var total = service.aggregate(List.of(matched, unmatched));

        assertEquals(130, total.calories());
        assertEquals(NutritionSource.PARTIAL_DATABASE, total.source());
        assertFalse(total.complete());
    }

    @Test
    void combinesDatabaseCalculationsWithAiEstimates() {
        FoodNutrition rice = food(
                130, 2.7, 28, 0.3, 0.1, 0.4, 1,
                100, "g");
        var matched = service.calculate(
                component("Rice", 100, "g"),
                Optional.of(new MatchCandidate(rice, 1)));
        var unmatched = service.calculate(
                component("Sauce", 20, "g"), Optional.empty());
        var estimated = service.applyAiEstimate(
                unmatched,
                new FoodComponentNutritionEstimate(
                        0, 40, 0, 10, 0, 8, 0, 120, 0.65));

        var total = service.aggregate(List.of(matched, estimated));

        assertEquals(170, total.calories());
        assertEquals(38, total.carbohydrates());
        assertEquals(NutritionSource.HYBRID_ESTIMATED, total.source());
        assertTrue(total.complete());
        assertTrue(estimated.requiresUserConfirmation());
    }

    private FoodVisionComponent component(String name, double amount, String unit) {
        return new FoodVisionComponent(
                name, amount, unit, 0.9, 0.8,
                "visible", "visible portion evidence");
    }

    private FoodNutrition food(
            double calories, double protein, double carbs, double fat, double sugar,
            double fiber, double sodium, double servingSize, String servingUnit) {
        FoodNutrition food = new FoodNutrition();
        food.setName("Database food");
        food.setCalories(BigDecimal.valueOf(calories));
        food.setProtein(BigDecimal.valueOf(protein));
        food.setCarbs(BigDecimal.valueOf(carbs));
        food.setFat(BigDecimal.valueOf(fat));
        food.setSugar(BigDecimal.valueOf(sugar));
        food.setFiber(BigDecimal.valueOf(fiber));
        food.setSodium(BigDecimal.valueOf(sodium));
        food.setServingSize(BigDecimal.valueOf(servingSize));
        food.setServingUnit(servingUnit);
        food.setActive(true);
        return food;
    }
}
