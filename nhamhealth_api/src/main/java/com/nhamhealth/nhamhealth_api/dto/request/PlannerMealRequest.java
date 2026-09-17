package com.nhamhealth.nhamhealth_api.dto.request;

import java.math.BigDecimal;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record PlannerMealRequest(
        @NotBlank(message = "English meal name is required") String nameEn,
                String nameKm,
                @NotNull(message = "Category is required") Integer categoryId,
                String descriptionEn,
                String descriptionKm,
                String imageUrl,
                @NotNull @DecimalMin(value = "0", message = "Calories cannot be negative") BigDecimal calories,
                @NotNull @DecimalMin(value = "0", message = "Protein cannot be negative") BigDecimal proteinGrams,
                @NotNull @DecimalMin(value = "0", message = "Carbs cannot be negative") BigDecimal carbsGrams,
                @NotNull @DecimalMin(value = "0", message = "Fat cannot be negative") BigDecimal fatGrams,
                Integer cookingTimeMinutes,
                String ingredientsText,
                String instructionsText,
                String tagsText,
                Boolean active) {
}
