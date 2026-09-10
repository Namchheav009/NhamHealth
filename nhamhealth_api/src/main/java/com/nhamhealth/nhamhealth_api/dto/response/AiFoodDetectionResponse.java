package com.nhamhealth.nhamhealth_api.dto.response;

public record AiFoodDetectionResponse(
        boolean foodDetected,
        String reason,
        String mealName,
        String type,
        boolean requiresDrinkDetails,
        double confidence) {
}
