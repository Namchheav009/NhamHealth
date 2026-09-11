package com.nhamhealth.nhamhealth_api.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record AdminIngredientRequest(
        @NotBlank @Size(max = 100) String ingredientName,
        @Size(max = 100) String ingredientNameKm,
        @NotBlank @Size(max = 50) String ingredientType,
        @Size(max = 30) String defaultUnit,
        @Size(max = 255) String description,
        @Size(max = 1000) String descriptionKm,
        @Size(max = 255) String imageUrl) {

    public AdminIngredientRequest(String ingredientName, String ingredientType, String defaultUnit, String description, String imageUrl) {
        this(ingredientName, null, ingredientType, defaultUnit, description, null, imageUrl);
    }
}
