package com.nhamhealth.nhamhealth_api.dto.response;

import java.util.List;

public record MealAdminRowDto(
        Integer mealId,
        String iconClass,
        String mainImageUrl,
        String thumbnailUrl,
        String mealName,
        String category,
        String calories,
        String servingSize,
        List<String> tags,
        String rating,
        int reviewCount,
        Integer favorites,
        String status,
        String updatedDate) {
}
