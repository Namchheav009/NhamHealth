package com.nhamhealth.nhamhealth_api.dto.response;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record FavoriteMealResponse(
        Integer id,
        String name,
        String imageUrl,
        BigDecimal calories,
        double rating,
        String category,
        LocalDateTime savedAt) {
}
