package com.nhamhealth.nhamhealth_api.service.meal;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.List;

import com.nhamhealth.nhamhealth_api.dto.response.MealPlanResponse;
import com.nhamhealth.nhamhealth_api.entity.PlannerMeal;

public final class PlannerMealContent {
    private PlannerMealContent() {}

    public static List<MealPlanResponse.IngredientItem> ingredients(PlannerMeal meal, String lang) {
        if (meal.getIngredientsText() == null || meal.getIngredientsText().isBlank()) return List.of();
        return meal.getIngredientsText().lines().map(line -> {
            String[] parts = line.split("\\|", -1);
            String name = localized(parts, lang);
            if (name.isBlank()) return null;
            BigDecimal quantity = null;
            if (parts.length > 1 && !parts[1].isBlank()) {
                try { quantity = new BigDecimal(parts[1].trim()); } catch (NumberFormatException ignored) { }
            }
            return new MealPlanResponse.IngredientItem(name, quantity,
                    parts.length > 2 ? parts[2].trim() : "");
        }).filter(item -> item != null).toList();
    }

    private static String localized(String[] parts, String lang) {
        if ("km".equalsIgnoreCase(lang) && parts.length > 3 && !parts[3].isBlank()) return parts[3].trim();
        return parts[0].trim();
    }

    public static List<String> instructions(PlannerMeal meal) {
        return meal.getInstructionsText() == null ? List.of()
                : meal.getInstructionsText().lines().map(String::trim)
                        .filter(line -> !line.isEmpty()).toList();
    }

    public static List<String> tags(PlannerMeal meal) {
        return meal.getTagsText() == null ? List.of()
                : Arrays.stream(meal.getTagsText().split(","))
                        .map(String::trim).filter(tag -> !tag.isEmpty()).toList();
    }
}
