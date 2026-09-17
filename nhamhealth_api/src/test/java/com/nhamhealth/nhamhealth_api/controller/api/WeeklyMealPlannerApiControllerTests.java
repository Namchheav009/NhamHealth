package com.nhamhealth.nhamhealth_api.controller.api;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.util.List;

import org.junit.jupiter.api.Test;

import com.nhamhealth.nhamhealth_api.entity.PlannerMeal;
import com.nhamhealth.nhamhealth_api.entity.MealCategory;
import com.nhamhealth.nhamhealth_api.entity.WeeklyMealRecommendation;
import com.nhamhealth.nhamhealth_api.repository.meal.WeeklyMealRecommendationRepository;

class WeeklyMealPlannerApiControllerTests {
    @Test
    void returnsLocalizedActiveAdminPlannerMeals() {
        WeeklyMealRecommendationRepository repository = mock(WeeklyMealRecommendationRepository.class);
        PlannerMeal meal = new PlannerMeal();
        meal.setPlannerMealId(42);
        meal.setNameEn("Grilled fish");
        meal.setNameKm("ត្រីអាំង");
        meal.setCategoryEn("Dinner");
        MealCategory category = new MealCategory();
        category.setCategoryId(7);
        meal.setCategory(category);
        meal.setCalories(new BigDecimal("510"));
        meal.setProteinGrams(new BigDecimal("38"));
        meal.setCarbsGrams(BigDecimal.ZERO);
        meal.setFatGrams(BigDecimal.ZERO);
        meal.setIngredientsText("Fish | 1 | piece | ត្រី");
        WeeklyMealRecommendation recommendation = new WeeklyMealRecommendation();
        recommendation.setPlannerMeal(meal);
        recommendation.setDayOfWeek("FRIDAY");
        recommendation.setMealSlot("DINNER");
        recommendation.setSortOrder(1);
        recommendation.setNote("High protein choice");
        when(repository.findAllByActiveTrueAndPlannerMealActiveTrueOrderBySortOrderAscRecommendationIdAsc())
                .thenReturn(List.of(recommendation));

        var response = new WeeklyMealPlannerApiController(repository).recommendations("km");
        assertEquals(1, response.getBody().size());
        assertEquals(42, response.getBody().getFirst().plannerMealId());
        assertEquals("ត្រីអាំង", response.getBody().getFirst().mealName());
        assertEquals("ត្រី", response.getBody().getFirst().ingredients().getFirst().name());
        assertEquals(BigDecimal.ONE, response.getBody().getFirst().ingredients().getFirst().quantity());
        assertEquals("FRIDAY", response.getBody().getFirst().dayOfWeek());
        assertEquals("DINNER", response.getBody().getFirst().mealSlot());
    }
}
