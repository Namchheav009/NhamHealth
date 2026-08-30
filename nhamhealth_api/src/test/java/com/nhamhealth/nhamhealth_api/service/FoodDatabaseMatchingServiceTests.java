package com.nhamhealth.nhamhealth_api.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.Test;

import com.nhamhealth.nhamhealth_api.entity.FoodNutrition;
import com.nhamhealth.nhamhealth_api.repository.FoodNutritionRepository;

class FoodDatabaseMatchingServiceTests {
    @Test
    void normalizesPluralFoodNamesBeforeMatching() {
        FoodNutritionRepository repository = mock(FoodNutritionRepository.class);
        when(repository.findAllByActiveTrue()).thenReturn(List.of(
                food("Grilled Chicken", "Chicken Breast Grilled")));
        FoodDatabaseMatchingService service = new FoodDatabaseMatchingService(repository, 0.78);

        var match = service.findReliableMatch("grilled chickens");

        assertTrue(match.isPresent());
        assertEquals("Grilled Chicken", match.get().food().getName());
        assertEquals(1, match.get().score());
    }

    @Test
    void appliesKnownRiceAliasWithoutForcingAnUnrelatedMatch() {
        FoodNutritionRepository repository = mock(FoodNutritionRepository.class);
        when(repository.findAllByActiveTrue()).thenReturn(List.of(
                food("Cooked Jasmine Rice", "Cooked Rice,Steamed Rice"),
                food("Rice Noodle Soup", "Kuy Teav")));
        FoodDatabaseMatchingService service = new FoodDatabaseMatchingService(repository, 0.78);

        var match = service.findReliableMatch("white rice");

        assertTrue(match.isPresent());
        assertEquals("Cooked Jasmine Rice", match.get().food().getName());
    }

    @Test
    void appliesALearnedUserCorrectionBeforeCatalogMatching() {
        FoodNutritionRepository repository = mock(FoodNutritionRepository.class);
        FoodCorrectionSuggestionService corrections = mock(FoodCorrectionSuggestionService.class);
        when(repository.findAllByActiveTrue()).thenReturn(List.of(
                food("Thai Iced Tea", "Thai Tea")));
        when(corrections.findLearnedCorrection("mystery tea"))
                .thenReturn(Optional.of("Thai Iced Tea"));
        FoodDatabaseMatchingService service = new FoodDatabaseMatchingService(
                repository, corrections, new FoodNameNormalizer(), 0.78);

        var match = service.findReliableMatch("Mystery Tea");

        assertTrue(match.isPresent());
        assertEquals("Thai Iced Tea", match.get().food().getName());
        assertEquals(1, match.get().score());
        verify(corrections).findLearnedCorrection("mystery tea");
    }

    private FoodNutrition food(String name, String aliases) {
        FoodNutrition food = new FoodNutrition();
        food.setName(name);
        food.setAliases(aliases);
        food.setCalories(BigDecimal.valueOf(100));
        food.setProtein(BigDecimal.ONE);
        food.setCarbs(BigDecimal.TEN);
        food.setFat(BigDecimal.ONE);
        food.setSugar(BigDecimal.ZERO);
        food.setServingSize(BigDecimal.valueOf(100));
        food.setServingUnit("g");
        food.setActive(true);
        return food;
    }
}
