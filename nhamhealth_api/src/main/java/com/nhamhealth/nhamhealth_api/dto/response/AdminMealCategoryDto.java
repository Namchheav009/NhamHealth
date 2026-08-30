package com.nhamhealth.nhamhealth_api.dto.response;

public record AdminMealCategoryDto(
        Integer categoryId,
        String categoryName,
        String description,
        boolean active,
        Integer sortOrder,
        long mealCount) {
}
