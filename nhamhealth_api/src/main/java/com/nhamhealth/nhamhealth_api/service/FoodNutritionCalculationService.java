package com.nhamhealth.nhamhealth_api.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.Locale;
import java.util.Optional;

import org.springframework.stereotype.Service;

import com.nhamhealth.nhamhealth_api.dto.ai.FoodVisionComponent;
import com.nhamhealth.nhamhealth_api.dto.ai.FoodComponentNutritionEstimate;
import com.nhamhealth.nhamhealth_api.dto.response.DetectedFoodComponent;
import com.nhamhealth.nhamhealth_api.dto.response.NutritionSource;
import com.nhamhealth.nhamhealth_api.dto.response.NutritionSummaryResponse;
import com.nhamhealth.nhamhealth_api.entity.FoodNutrition;
import com.nhamhealth.nhamhealth_api.service.FoodDatabaseMatchingService.MatchCandidate;

@Service
public class FoodNutritionCalculationService {
    private static final int NUTRIENT_SCALE = 1;

    public DetectedFoodComponent calculate(
            FoodVisionComponent detected, Optional<MatchCandidate> possibleMatch) {
        if (possibleMatch.isEmpty()) return unmatched(detected);
        MatchCandidate match = possibleMatch.get();
        FoodNutrition food = match.food();
        Optional<BigDecimal> factor = scaleFactor(
                detected.estimatedAmount(), detected.unit(),
                food.getServingSize(), food.getServingUnit());
        if (factor.isEmpty()) {
            return new DetectedFoodComponent(
                    detected.name(), detected.estimatedAmount(), detected.unit(),
                    detected.confidence(), detected.portionConfidence(),
                    detected.preparationMethod(), detected.visibleEvidence(),
                    detected.componentType(), detected.liquidVolumeMl(), detected.beverageType(),
                    true, food.getId(), food.getName(), match.score(),
                    0, 0, 0, 0, 0, 0, 0,
                    NutritionSource.UNAVAILABLE, true);
        }
        BigDecimal multiplier = factor.get();
        return new DetectedFoodComponent(
                detected.name(), detected.estimatedAmount(), detected.unit(),
                detected.confidence(), detected.portionConfidence(),
                detected.preparationMethod(), detected.visibleEvidence(),
                detected.componentType(), detected.liquidVolumeMl(), detected.beverageType(),
                true, food.getId(), food.getName(), match.score(),
                scaled(food.getCalories(), multiplier),
                scaled(food.getProtein(), multiplier),
                scaled(food.getCarbs(), multiplier),
                scaled(food.getFat(), multiplier),
                scaled(food.getSugar(), multiplier),
                scaled(food.getFiber(), multiplier),
                scaled(food.getSodium(), multiplier),
                NutritionSource.DATABASE_CALCULATED, false);
    }

    public NutritionSummaryResponse aggregate(List<DetectedFoodComponent> components) {
        if (components == null || components.isEmpty()) {
            return NutritionSummaryResponse.unavailable();
        }
        double calories = 0;
        double protein = 0;
        double carbohydrates = 0;
        double fat = 0;
        double sugar = 0;
        double fiber = 0;
        double sodium = 0;
        int databaseCalculated = 0;
        int aiEstimated = 0;
        for (DetectedFoodComponent component : components) {
            calories += component.calories();
            protein += component.protein();
            carbohydrates += component.carbohydrates();
            fat += component.fat();
            sugar += component.sugar();
            fiber += component.fiber();
            sodium += component.sodium();
            if (component.nutritionSource() == NutritionSource.DATABASE_CALCULATED) {
                databaseCalculated++;
            } else if (component.nutritionSource() == NutritionSource.AI_ESTIMATED) {
                aiEstimated++;
            }
        }
        int available = databaseCalculated + aiEstimated;
        boolean complete = available == components.size();
        NutritionSource source;
        if (!complete) {
            source = available == 0
                    ? NutritionSource.UNAVAILABLE : NutritionSource.PARTIAL_DATABASE;
        } else if (aiEstimated == 0) {
            source = NutritionSource.DATABASE_CALCULATED;
        } else if (databaseCalculated == 0) {
            source = NutritionSource.AI_ESTIMATED;
        } else {
            source = NutritionSource.HYBRID_ESTIMATED;
        }
        return new NutritionSummaryResponse(
                round(calories), round(protein), round(carbohydrates), round(fat),
                round(sugar), round(fiber), round(sodium), source, complete);
    }

    public DetectedFoodComponent applyAiEstimate(
            DetectedFoodComponent component,
            FoodComponentNutritionEstimate estimate) {
        return new DetectedFoodComponent(
                component.name(), component.estimatedAmount(), component.unit(),
                component.confidence(), component.portionConfidence(),
                component.preparationMethod(), component.visibleEvidence(),
                component.componentType(), component.liquidVolumeMl(), component.beverageType(),
                component.databaseMatched(), component.matchedFoodId(),
                component.matchedFoodName(), component.databaseMatchConfidence(),
                round(estimate.calories()),
                round(estimate.protein()),
                round(estimate.carbohydrates()),
                round(estimate.fat()),
                round(estimate.sugar()),
                round(estimate.fiber()),
                round(estimate.sodium()),
                NutritionSource.AI_ESTIMATED,
                true);
    }

    Optional<BigDecimal> scaleFactor(
            double detectedAmount, String detectedUnit,
            BigDecimal databaseServingSize, String databaseServingUnit) {
        if (!Double.isFinite(detectedAmount) || detectedAmount <= 0
                || databaseServingSize == null || databaseServingSize.signum() <= 0) {
            return Optional.empty();
        }
        UnitAmount detected = toBaseUnit(BigDecimal.valueOf(detectedAmount), detectedUnit);
        UnitAmount database = toBaseUnit(databaseServingSize, databaseServingUnit);
        if (detected == null || database == null || !detected.dimension().equals(database.dimension())) {
            return Optional.empty();
        }
        return Optional.of(detected.amount().divide(database.amount(), 8, RoundingMode.HALF_UP));
    }

    private DetectedFoodComponent unmatched(FoodVisionComponent detected) {
        return new DetectedFoodComponent(
                detected.name(), detected.estimatedAmount(), detected.unit(),
                detected.confidence(), detected.portionConfidence(),
                detected.preparationMethod(), detected.visibleEvidence(),
                detected.componentType(), detected.liquidVolumeMl(), detected.beverageType(),
                false, null, null, 0,
                0, 0, 0, 0, 0, 0, 0,
                NutritionSource.UNAVAILABLE, true);
    }

    private UnitAmount toBaseUnit(BigDecimal amount, String rawUnit) {
        if (rawUnit == null || rawUnit.isBlank()) return null;
        String unit = rawUnit.toLowerCase(Locale.ROOT).replace(".", "").trim();
        return switch (unit) {
            case "g", "gram", "grams" -> new UnitAmount("mass", amount);
            case "kg", "kilogram", "kilograms" ->
                    new UnitAmount("mass", amount.multiply(BigDecimal.valueOf(1_000)));
            case "mg", "milligram", "milligrams" ->
                    new UnitAmount("mass", amount.divide(BigDecimal.valueOf(1_000), 8, RoundingMode.HALF_UP));
            case "ml", "milliliter", "milliliters", "millilitre", "millilitres" ->
                    new UnitAmount("volume", amount);
            case "l", "liter", "liters", "litre", "litres" ->
                    new UnitAmount("volume", amount.multiply(BigDecimal.valueOf(1_000)));
            case "tablespoon", "tablespoons", "tbsp" ->
                    new UnitAmount("volume", amount.multiply(BigDecimal.valueOf(15)));
            case "teaspoon", "teaspoons", "tsp" ->
                    new UnitAmount("volume", amount.multiply(BigDecimal.valueOf(5)));
            case "piece", "pieces" -> new UnitAmount("count:piece", amount);
            case "slice", "slices" -> new UnitAmount("count:slice", amount);
            case "bowl", "bowls" -> new UnitAmount("count:bowl", amount);
            case "cup", "cups" -> new UnitAmount("count:cup", amount);
            case "plate", "plates" -> new UnitAmount("count:plate", amount);
            case "serving", "servings" -> new UnitAmount("count:serving", amount);
            default -> null;
        };
    }

    private double scaled(BigDecimal nutrient, BigDecimal factor) {
        if (nutrient == null) return 0;
        return nutrient.multiply(factor)
                .setScale(NUTRIENT_SCALE, RoundingMode.HALF_UP)
                .doubleValue();
    }

    private double round(double value) {
        return BigDecimal.valueOf(value)
                .setScale(NUTRIENT_SCALE, RoundingMode.HALF_UP)
                .doubleValue();
    }

    private record UnitAmount(String dimension, BigDecimal amount) {
    }
}
