package com.nhamhealth.nhamhealth_api.service;

import com.nhamhealth.nhamhealth_api.dto.response.AiFoodAnalysisResponse;

public record AiFoodModelResult(
        AiFoodAnalysisResponse response,
        String modelName,
        String promptVersion,
        boolean nutritionFallbackUsed,
        int promptTokens,
        int completionTokens,
        long latencyMs) {
}
