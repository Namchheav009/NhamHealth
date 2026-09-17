package com.nhamhealth.nhamhealth_api.dto.response;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public record MealPlanResponse(
        Integer planId, LocalDate planDate, String mealType, BigDecimal servings,
        Integer plannerMealId, String mealName, Integer categoryId, String category, String imageUrl,
        BigDecimal calories, BigDecimal proteinGrams, BigDecimal carbsGrams, BigDecimal fatGrams,
        String description, Integer cookingTimeMinutes, String difficulty,
        List<IngredientItem> ingredients, List<String> instructions, List<String> tags) {
    public record IngredientItem(String name, BigDecimal quantity, String unit) {}
}
