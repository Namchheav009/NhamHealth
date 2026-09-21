package com.nhamhealth.nhamhealth_api.dto.response;

import java.math.BigDecimal;

/**
 * AI-recommended food or beverage item drawn directly from the database
 * with nutritional values and IBM watsonx Granite reasoning.
 */
public record ForecastRecommendationItem(
        String itemType, // "FOOD" or "BEVERAGE"
        Integer sourceId,
        String sourceTable, // "planner_meals" or "food_nutrition"
        String name,
        String category,
        BigDecimal calories,
        BigDecimal proteinGrams,
        BigDecimal carbsGrams,
        BigDecimal fatGrams,
        String servingUnit,
        BigDecimal servingSize,
        String imageUrl,
        String rationale,
        String ibmBadge
) {}
