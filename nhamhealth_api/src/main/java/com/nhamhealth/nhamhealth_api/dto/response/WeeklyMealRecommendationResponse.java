package com.nhamhealth.nhamhealth_api.dto.response;

import java.math.BigDecimal;
import java.util.List;

public record WeeklyMealRecommendationResponse(
        Integer id,
        String dayOfWeek,
        String mealSlot,
        Integer plannerMealId,
        String mealName,
        String imageUrl,
        BigDecimal calories,
        BigDecimal proteinGrams,
        BigDecimal carbsGrams,
        BigDecimal fatGrams,
        Integer categoryId,
        String category,
        String description,
        Integer cookingTimeMinutes,
        String difficulty,
        List<MealPlanResponse.IngredientItem> ingredients,
        List<String> instructions,
        List<String> tags,
        String note,
        Integer sortOrder,
        List<Integer> categoryIds,
        BigDecimal fiberGrams,
        BigDecimal sugarGrams,
        BigDecimal sodiumMg,
        BigDecimal saturatedFatGrams,
        BigDecimal servingSize,
        String servingUnit,
        String nutritionDataQuality,
        List<String> dietTypes,
        List<String> allergens,
        String whyRecommended) {

    public WeeklyMealRecommendationResponse(
            Integer id, String dayOfWeek, String mealSlot, Integer plannerMealId,
            String mealName, String imageUrl, BigDecimal calories, BigDecimal proteinGrams,
            BigDecimal carbsGrams, BigDecimal fatGrams, Integer categoryId, String category,
            String description, Integer cookingTimeMinutes, String difficulty,
            List<MealPlanResponse.IngredientItem> ingredients, List<String> instructions,
            List<String> tags, String note, Integer sortOrder) {
        this(id, dayOfWeek, mealSlot, plannerMealId, mealName, imageUrl, calories, proteinGrams,
                carbsGrams, fatGrams, categoryId, category, description, cookingTimeMinutes,
                difficulty, ingredients, instructions, tags, note, sortOrder,
                categoryId != null ? List.of(categoryId) : List.of(),
                null, null, null, null, null, null, "UNVERIFIED", List.of(), List.of(), "");
    }

    public WeeklyMealRecommendationResponse(
            Integer id, String dayOfWeek, String mealSlot, Integer plannerMealId,
            String mealName, String imageUrl, BigDecimal calories, BigDecimal proteinGrams,
            BigDecimal carbsGrams, BigDecimal fatGrams, Integer categoryId, String category,
            String description, Integer cookingTimeMinutes, String difficulty,
            List<MealPlanResponse.IngredientItem> ingredients, List<String> instructions,
            List<String> tags, String note, Integer sortOrder, List<Integer> categoryIds) {
        this(id, dayOfWeek, mealSlot, plannerMealId, mealName, imageUrl, calories, proteinGrams,
                carbsGrams, fatGrams, categoryId, category, description, cookingTimeMinutes,
                difficulty, ingredients, instructions, tags, note, sortOrder, categoryIds,
                null, null, null, null, null, null, "UNVERIFIED", List.of(), List.of(), "");
    }
}
