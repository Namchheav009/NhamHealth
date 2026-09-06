package com.nhamhealth.nhamhealth_api.dto.response;

import java.math.BigDecimal;

public record RecommendedMealResponse(
        Integer id,
        String name,
        String imageUrl,
        BigDecimal calories,
        BigDecimal proteinGrams,
        Integer cookingTimeMinutes,
        double rating,
        Integer recommendationId,
        Integer moodId,
        String reason) {
}
