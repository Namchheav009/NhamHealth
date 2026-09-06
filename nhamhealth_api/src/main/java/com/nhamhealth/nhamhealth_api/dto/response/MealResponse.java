package com.nhamhealth.nhamhealth_api.dto.response;

import java.math.BigDecimal;

import com.nhamhealth.nhamhealth_api.entity.Meal;

/** A published meal displayed by the mobile application. */
public record MealResponse(
        Integer id,
        String name,
        Integer categoryId,
        String category,
        String imageUrl,
        BigDecimal calories,
        BigDecimal proteinGrams,
        String description,
        Integer cookingTimeMinutes,
        String difficulty,
        Integer servings) {

    public static MealResponse from(Meal meal) {
        String categoryName = meal.getCategory() == null
                ? "Uncategorized"
                : meal.getCategory().getCategoryName();
        return new MealResponse(
                meal.getMealId(),
                meal.getMealName(),
                meal.getCategory() == null ? null : meal.getCategory().getCategoryId(),
                categoryName,
                meal.getMainImageUrl(),
                meal.getCaloriesCached(),
                meal.getProteinGramsCached(),
                meal.getDescription(),
                meal.getCookingTimeMinutes(),
                meal.getDifficulty(),
                meal.getServings());
    }
}
