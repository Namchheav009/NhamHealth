package com.nhamhealth.nhamhealth_api.service.ai;

import com.nhamhealth.nhamhealth_api.dto.ai.FoodVisionResult;

public record AiFoodModelResult(
        FoodVisionResult response,
        String modelName,
        String promptVersion,
        boolean nutritionFallbackUsed,
        int promptTokens,
        int completionTokens,
        long latencyMs) {
}
