package com.nhamhealth.nhamhealth_api.dto;

import java.util.List;

public record MealAdminRowDto(
        Integer mealId,
        String iconClass,
        String mealName,
        String category,
        String calories,
        String servingSize,
        List<String> tags,
        String reviews,
        Integer favorites,
        String status,
        String updatedDate) {
}
