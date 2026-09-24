package com.nhamhealth.nhamhealth_api.dto.request;

import java.math.BigDecimal;
import java.util.List;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record PlannerMealRequest(
        @NotBlank(message = "English meal name is required") String nameEn,
        String nameKm,
        Integer categoryId,
        List<Integer> categoryIds,
        String descriptionEn,
        String descriptionKm,
        String imageUrl,
        @NotNull @DecimalMin(value = "0", message = "Calories cannot be negative") BigDecimal calories,
        @NotNull @DecimalMin(value = "0", message = "Protein cannot be negative") BigDecimal proteinGrams,
        @NotNull @DecimalMin(value = "0", message = "Carbs cannot be negative") BigDecimal carbsGrams,
        @NotNull @DecimalMin(value = "0", message = "Fat cannot be negative") BigDecimal fatGrams,
        Integer cookingTimeMinutes,
        String ingredientsText,
        String ingredientsTextKm,
        String instructionsText,
        String instructionsTextKm,
        String tagsText,
        String tagsTextKm,
        List<String> weightGoals,
        Boolean active) {

    public PlannerMealRequest(
            String nameEn,
            String nameKm,
            Integer categoryId,
            List<Integer> categoryIds,
            String descriptionEn,
            String descriptionKm,
            String imageUrl,
            BigDecimal calories,
            BigDecimal proteinGrams,
            BigDecimal carbsGrams,
            BigDecimal fatGrams,
            Integer cookingTimeMinutes,
            String ingredientsText,
            String ingredientsTextKm,
            String instructionsText,
            String instructionsTextKm,
            String tagsText,
            String tagsTextKm,
            Boolean active) {
        this(nameEn, nameKm, categoryId, categoryIds, descriptionEn, descriptionKm, imageUrl,
                calories, proteinGrams, carbsGrams, fatGrams, cookingTimeMinutes,
                ingredientsText, ingredientsTextKm, instructionsText, instructionsTextKm,
                tagsText, tagsTextKm, List.of("LOSE_WEIGHT", "MAINTAIN_HEALTH", "GAIN_WEIGHT"), active);
    }

    public Integer effectiveCategoryId() {
        if (categoryId != null)
            return categoryId;
        if (categoryIds != null && !categoryIds.isEmpty())
            return categoryIds.getFirst();
        return null;
    }
}
