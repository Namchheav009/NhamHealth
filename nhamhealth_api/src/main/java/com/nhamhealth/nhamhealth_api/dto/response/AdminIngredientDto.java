package com.nhamhealth.nhamhealth_api.dto.response;

public record AdminIngredientDto(
        Integer ingredientId,
        String ingredientName,
        String ingredientNameKm,
        String ingredientType,
        String defaultUnit,
        String description,
        String descriptionKm,
        String imageUrl) {
}
