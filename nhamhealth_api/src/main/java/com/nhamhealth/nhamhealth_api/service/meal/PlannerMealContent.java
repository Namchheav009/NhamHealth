package com.nhamhealth.nhamhealth_api.service.meal;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.List;

import com.nhamhealth.nhamhealth_api.dto.response.MealPlanResponse;
import com.nhamhealth.nhamhealth_api.entity.PlannerMeal;

public final class PlannerMealContent {
    private PlannerMealContent() {
    }

    public static List<MealPlanResponse.IngredientItem> ingredients(PlannerMeal meal) {
        return ingredients(meal, "en");
    }

    public static List<MealPlanResponse.IngredientItem> ingredients(PlannerMeal meal, String lang) {
        if (meal == null)
            return List.of();
        boolean isKhmer = "km".equalsIgnoreCase(lang);

        if (isKhmer && meal.getIngredientsTextKm() != null && !meal.getIngredientsTextKm().isBlank()) {
            return parseIngredientLines(meal.getIngredientsTextKm());
        }

        if (meal.getIngredientsText() == null || meal.getIngredientsText().isBlank())
            return List.of();
        return meal.getIngredientsText().lines().map(line -> {
            String[] parts = line.split("\\|", -1);
            String name = localizedLegacy(parts, lang);
            if (name.isBlank())
                return null;
            BigDecimal quantity = null;
            if (parts.length > 1 && !parts[1].isBlank()) {
                try {
                    quantity = new BigDecimal(parts[1].trim());
                } catch (NumberFormatException ignored) {
                }
            }
            return new MealPlanResponse.IngredientItem(name, quantity,
                    parts.length > 2 ? parts[2].trim() : "");
        }).filter(item -> item != null).toList();
    }

    private static List<MealPlanResponse.IngredientItem> parseIngredientLines(String text) {
        return text.lines().map(line -> {
            String[] parts = line.split("\\|", -1);
            String name = parts[0].trim();
            if (name.isBlank())
                return null;
            BigDecimal quantity = null;
            if (parts.length > 1 && !parts[1].isBlank()) {
                try {
                    quantity = new BigDecimal(parts[1].trim());
                } catch (NumberFormatException ignored) {
                }
            }
            return new MealPlanResponse.IngredientItem(name, quantity,
                    parts.length > 2 ? parts[2].trim() : "");
        }).filter(item -> item != null).toList();
    }

    private static String localizedLegacy(String[] parts, String lang) {
        if ("km".equalsIgnoreCase(lang) && parts.length > 3 && !parts[3].isBlank())
            return parts[3].trim();
        return parts[0].trim();
    }

    public static List<String> instructions(PlannerMeal meal) {
        return instructions(meal, "en");
    }

    public static List<String> instructions(PlannerMeal meal, String lang) {
        if (meal == null)
            return List.of();
        String text = "km".equalsIgnoreCase(lang) && meal.getInstructionsTextKm() != null
                && !meal.getInstructionsTextKm().isBlank()
                        ? meal.getInstructionsTextKm()
                        : meal.getInstructionsText();
        return text == null ? List.of()
                : text.lines().map(String::trim)
                        .filter(line -> !line.isEmpty()).toList();
    }

    public static List<String> tags(PlannerMeal meal) {
        return tags(meal, "en");
    }

    public static List<String> tags(PlannerMeal meal, String lang) {
        if (meal == null)
            return List.of();
        String text = "km".equalsIgnoreCase(lang) && meal.getTagsTextKm() != null && !meal.getTagsTextKm().isBlank()
                ? meal.getTagsTextKm()
                : meal.getTagsText();
        return text == null ? List.of()
                : Arrays.stream(text.split(","))
                        .map(String::trim).filter(tag -> !tag.isEmpty()).toList();
    }
}
