package com.nhamhealth.nhamhealth_api.dto.response;

import java.math.BigDecimal;

public record AdminMealIngredientDto(
        Integer ingredientId,
        String ingredientName,
        String defaultUnit,
        BigDecimal quantity,
        String unit,
        String preparationNote) {
}
