package com.nhamhealth.nhamhealth_api.dto.response;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record AdminMealLogDto(
        Integer mealLogId,
        Integer userId,
        Integer mealLogTypeId,
        Integer mealId,
        Integer servingSizeId,
        String customFoodName,
        BigDecimal quantity,
        String entryMethod,
        LocalDateTime loggedAt,
        String notes) {
}
