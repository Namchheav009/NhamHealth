package com.nhamhealth.nhamhealth_api.dto.response;

public enum NutritionSource {
    DATABASE_CALCULATED,
    AI_ESTIMATED,
    HYBRID_ESTIMATED,
    USER_ENTERED,
    PARTIAL_DATABASE,
    UNAVAILABLE
}
