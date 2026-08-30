package com.nhamhealth.nhamhealth_api.dto.response;

import java.time.LocalDateTime;

public record AdminMealReviewDto(
        Integer reviewId,
        String userEmail,
        Integer rating,
        String reviewText,
        LocalDateTime createdAt) {
}