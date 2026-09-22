package com.nhamhealth.nhamhealth_api.service.ai;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.Test;

import com.nhamhealth.nhamhealth_api.dto.request.IngredientAnalysisRequest;
import com.nhamhealth.nhamhealth_api.entity.FoodNutrition;
import com.nhamhealth.nhamhealth_api.service.catalog.FoodDatabaseMatchingService;
import com.nhamhealth.nhamhealth_api.service.catalog.FoodDatabaseMatchingService.MatchCandidate;

class AiIngredientAnalysisServiceTests {
    private final FoodDatabaseMatchingService matching = mock(FoodDatabaseMatchingService.class);
    private final AiIngredientAnalysisService service = new AiIngredientAnalysisService(
            matching, null, "https://example.com", "", "test-model", "fallback-model");

    @Test
    void usesCatalogServingSizeForGramAmounts() {
        FoodNutrition food = food("Rice", "g", 100, 130);
        food.setImageUrl("https://cdn.example.com/ingredients/rice.jpg");
        when(matching.findReliableMatch("Rice")).thenReturn(Optional.of(new MatchCandidate(food, 0.95)));

        var result = service.analyze(new IngredientAnalysisRequest("Rice bowl", List.of("200 g Rice"), 2, "en"));

        assertEquals(1, result.databaseMatchedCount());
        assertEquals(130, result.totalCalories());
        assertEquals("https://cdn.example.com/ingredients/rice.jpg", result.ingredients().getFirst().imageUrl());
        assertTrue(result.ingredients().getFirst().portion().contains("2.00 catalog servings"));
    }

    @Test
    void excludesNutritionWhenQuantityUnitCannotMatchCatalog() {
        FoodNutrition food = food("Milk", "cup", 1, 120);
        when(matching.findReliableMatch("Milk")).thenReturn(Optional.of(new MatchCandidate(food, 0.95)));

        var result = service.analyze(new IngredientAnalysisRequest("Drink", List.of("200 g Milk"), 1, "en"));

        assertEquals(1, result.databaseMatchedCount());
        assertEquals(0, result.totalCalories());
        assertTrue(result.ingredients().getFirst().portion().contains("excluded"));
    }

    @Test
    void doesNotAcceptWeakCatalogCandidates() {
        when(matching.findReliableMatch("Mystery herb")).thenReturn(Optional.empty());

        var result = service.analyze(new IngredientAnalysisRequest("Soup", List.of("Mystery herb"), 1, "en"));

        assertEquals(0, result.databaseMatchedCount());
        verify(matching, never()).findCandidates(anyString(), anyInt());
    }

    private static FoodNutrition food(String name, String unit, int size, int calories) {
        FoodNutrition food = new FoodNutrition();
        food.setName(name);
        food.setServingUnit(unit);
        food.setServingSize(BigDecimal.valueOf(size));
        food.setCalories(BigDecimal.valueOf(calories));
        food.setProtein(BigDecimal.ZERO);
        food.setCarbs(BigDecimal.ZERO);
        food.setFat(BigDecimal.ZERO);
        return food;
    }
}
