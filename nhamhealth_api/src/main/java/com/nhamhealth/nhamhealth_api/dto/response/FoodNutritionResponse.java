package com.nhamhealth.nhamhealth_api.dto.response;

import java.math.BigDecimal;
import com.nhamhealth.nhamhealth_api.entity.FoodNutrition;

public record FoodNutritionResponse(
        Integer id, String name, BigDecimal calories, BigDecimal protein,
        BigDecimal carbs, BigDecimal fat, BigDecimal sugar, BigDecimal fiber, BigDecimal sodium,
        BigDecimal servingSize, String servingUnit) {
    public static FoodNutritionResponse from(FoodNutrition food) {
        return new FoodNutritionResponse(food.getId(), food.getName(), food.getCalories(),
                food.getProtein(), food.getCarbs(), food.getFat(), food.getSugar(),
                food.getFiber(), food.getSodium(),
                food.getServingSize(), food.getServingUnit());
    }
}
