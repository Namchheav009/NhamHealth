package com.nhamhealth.nhamhealth_api.dto.request;

import java.math.BigDecimal;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record AdminMealIngredientRequest(
        @NotNull Integer ingredientId,
        @DecimalMin("0.0") @Digits(integer = 8, fraction = 2) BigDecimal quantity,
        @Size(max = 30) String unit,
        @Size(max = 150) String preparationNote) {
}
