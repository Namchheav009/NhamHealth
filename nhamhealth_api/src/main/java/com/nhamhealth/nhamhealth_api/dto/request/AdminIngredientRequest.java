package com.nhamhealth.nhamhealth_api.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record AdminIngredientRequest(
        @NotBlank @Size(max = 100) String ingredientName,
        @NotBlank @Size(max = 50) String ingredientType,
        @Size(max = 30) String defaultUnit,
        @Size(max = 255) String description,
        @Size(max = 255) String imageUrl) {
}
