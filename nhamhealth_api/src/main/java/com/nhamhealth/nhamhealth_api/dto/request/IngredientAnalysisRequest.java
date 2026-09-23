package com.nhamhealth.nhamhealth_api.dto.request;

import java.util.List;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Pattern;

public record IngredientAnalysisRequest(
        @Size(max = 150) String mealName,
        @NotEmpty(message = "At least one ingredient must be provided")
        @Size(max = 50) List<@NotBlank @Size(max = 150) String> ingredients,
        @Min(1) @Max(100) Integer servings,
        @Pattern(regexp = "en|km", flags = Pattern.Flag.CASE_INSENSITIVE) String lang
) {
    public IngredientAnalysisRequest {
        if (servings == null) {
            servings = 1;
        }
        if (lang == null || lang.isBlank()) {
            lang = "km";
        }
    }
}
