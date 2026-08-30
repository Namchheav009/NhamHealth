package com.nhamhealth.nhamhealth_api.dto.request;

import java.math.BigDecimal;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;

public record RecipeIngredientRequest(
        @NotBlank String name,
        @Positive BigDecimal amount,
        String unit,
        String preparationNote) { }
