package com.nhamhealth.nhamhealth_api.dto.response;

import java.math.BigDecimal;

public record AdminMealNutritionDto(
        Integer nutrientId,
        String nutrientName,
        BigDecimal amountPerServing,
        String unit) {
}