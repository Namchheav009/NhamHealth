package com.nhamhealth.nhamhealth_api.dto.response;

public record AdminMealCategoryDto(
        Integer categoryId,
        String categoryName,
        String categoryNameKm,
        String description,
        String descriptionKm,
        boolean active,
        Integer sortOrder,
        long mealCount) {
}
