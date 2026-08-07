package com.nhamhealth.nhamhealth_api.dto.request;

import java.math.BigDecimal;
import java.util.List;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;

public record AdminMealRequest(
        @NotBlank @Size(max = 150) String mealName,
        @NotNull Integer categoryId,
        @DecimalMin("0.0") BigDecimal calories,
        @NotNull @Min(1) @Max(100) Integer servings,
        @Size(max = 500) String description,
        @Size(max = 20) String difficulty,
        @Min(0) @Max(1440) Integer cookingTimeMinutes,
        boolean published,
        @NotBlank @Size(max = 255) String mainImageUrl,
        @NotEmpty List<@Valid AdminRecipeStepRequest> recipeSteps) {
}
