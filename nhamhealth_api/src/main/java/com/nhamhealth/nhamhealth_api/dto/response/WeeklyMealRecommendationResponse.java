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
        Integer sortOrder) {
}
