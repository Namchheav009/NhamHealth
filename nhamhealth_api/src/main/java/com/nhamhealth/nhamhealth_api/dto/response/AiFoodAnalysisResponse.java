package com.nhamhealth.nhamhealth_api.dto.response;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public record AiFoodAnalysisResponse(
        Integer analysisId,
        String name,
        String analysis,
        double confidence,
        double calories,
        double protein,
        double carbs,
        double fat,
        double sugar,
        double servingSize,
        String servingUnit,
        String recommendationTitle,
        String recommendation,
        boolean databaseMatched,
        double databaseMatchConfidence,
        boolean needsUserConfirmation,
        String dataSource,
        String disclaimer,
        String privacyNotice) {

    public AiFoodAnalysisResponse withAnalysisId(Integer value) {
        return new AiFoodAnalysisResponse(value, name, analysis, confidence, calories, protein,
                carbs, fat, sugar, servingSize, servingUnit, recommendationTitle,
                recommendation, databaseMatched, databaseMatchConfidence,
                needsUserConfirmation, dataSource, disclaimer, privacyNotice);
    }
}
