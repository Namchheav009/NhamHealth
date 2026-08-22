package com.nhamhealth.nhamhealth_api.dto.response;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public interface MealAdminAggregateProjection {
    Integer getMealId();

    String getMealName();

    String getCategory();

    String getMainImageUrl();

    BigDecimal getCalories();

    Integer getServings();

    Boolean getPublished();

    LocalDateTime getUpdatedAt();

    Double getRating();

    Long getReviewCount();

    Long getFavorites();
}
