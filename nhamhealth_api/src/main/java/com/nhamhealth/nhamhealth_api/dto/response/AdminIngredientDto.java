package com.nhamhealth.nhamhealth_api.dto.response;

public record AdminIngredientDto(
        Integer ingredientId,
        String ingredientName,
        String ingredientType,
        String defaultUnit,
        String description,
        String imageUrl) {
}
