package com.nhamhealth.nhamhealth_api.dto.request;

import java.math.BigDecimal;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record AdminMealIngredientRequest(
        Integer ingredientId,
        @Size(max = 100) String ingredientName,
        @Size(max = 50) String ingredientType,
        @Size(max = 30) String defaultUnit,
        @DecimalMin("0.0") @Digits(integer = 8, fraction = 2) BigDecimal quantity,
        @Size(max = 30) String unit,
        @Size(max = 150) String preparationNote,
        @Size(max = 100) String ingredientNameKm,
        @Size(max = 150) String preparationNoteKm) {

    public AdminMealIngredientRequest(Integer ingredientId, BigDecimal quantity, String unit,
            String preparationNote, String ingredientNameKm, String preparationNoteKm) {
        this(ingredientId, null, null, null, quantity, unit, preparationNote,
                ingredientNameKm, preparationNoteKm);
    }
}
