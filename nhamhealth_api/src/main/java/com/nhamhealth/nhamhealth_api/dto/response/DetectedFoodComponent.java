package com.nhamhealth.nhamhealth_api.dto.response;

public record DetectedFoodComponent(
        String name,
        double estimatedAmount,
        String unit,
        double confidence,
        double portionConfidence,
        String preparationMethod,
        String visibleEvidence,
        String componentType,
        double liquidVolumeMl,
        String beverageType,
        boolean databaseMatched,
        Integer matchedFoodId,
        String matchedFoodName,
        double databaseMatchConfidence,
        double calories,
        double protein,
        double carbohydrates,
        double fat,
        double sugar,
        double fiber,
        double sodium,
        NutritionSource nutritionSource,
        boolean requiresUserConfirmation) {
}
