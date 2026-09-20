package com.nhamhealth.nhamhealth_api.service.meal;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.Locale;
import java.util.Optional;

import org.springframework.stereotype.Service;

import com.nhamhealth.nhamhealth_api.dto.ai.FoodComponentNutritionEstimate;
import com.nhamhealth.nhamhealth_api.dto.ai.FoodVisionComponent;
import com.nhamhealth.nhamhealth_api.dto.response.DetectedFoodComponent;
import com.nhamhealth.nhamhealth_api.dto.response.NutritionSource;
import com.nhamhealth.nhamhealth_api.dto.response.NutritionSummaryResponse;
import com.nhamhealth.nhamhealth_api.entity.FoodNutrition;
import com.nhamhealth.nhamhealth_api.service.catalog.FoodDatabaseMatchingService.MatchCandidate;

@Service
public class FoodNutritionCalculationService {
    private static final int NUTRIENT_SCALE = 1;

    public DetectedFoodComponent calculate(
            FoodVisionComponent detected, Optional<MatchCandidate> possibleMatch) {
        if (possibleMatch.isEmpty())
            return unmatched(detected);
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
                    true, food.getId(), food.getName(), food.getImageUrl(), match.score(),
                    0, 0, 0, 0, 0, 0, 0,
                    NutritionSource.UNAVAILABLE, true);
        }
        BigDecimal multiplier = factor.get();
        return new DetectedFoodComponent(
                detected.name(), detected.estimatedAmount(), detected.unit(),
                detected.confidence(), detected.portionConfidence(),
                detected.preparationMethod(), detected.visibleEvidence(),
                detected.componentType(), detected.liquidVolumeMl(), detected.beverageType(),
                true, food.getId(), food.getName(), food.getImageUrl(), match.score(),
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
                    ? NutritionSource.UNAVAILABLE
                    : NutritionSource.PARTIAL_DATABASE;
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
                component.matchedFoodName(), component.imageUrl(), component.databaseMatchConfidence(),
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

    public DetectedFoodComponent estimateFallback(
            DetectedFoodComponent component,
            FoodVisionComponent detected) {
        double grams = toApproximateGrams(detected.estimatedAmount(), detected.unit());
        double factor = Math.max(0.01, grams / 100.0);
        NutrientProfile profile = resolveNutrientProfile(detected);

        return new DetectedFoodComponent(
                component.name(), component.estimatedAmount(), component.unit(),
                component.confidence(), component.portionConfidence(),
                component.preparationMethod(), component.visibleEvidence(),
                component.componentType(), component.liquidVolumeMl(), component.beverageType(),
                component.databaseMatched(), component.matchedFoodId(),
                component.matchedFoodName(), component.imageUrl(), component.databaseMatchConfidence(),
                round(profile.calories * factor),
                round(profile.protein * factor),
                round(profile.carbohydrates * factor),
                round(profile.fat * factor),
                round(profile.sugar * factor),
                round(profile.fiber * factor),
                round(profile.sodium * factor),
                NutritionSource.AI_ESTIMATED,
                true);
    }

    private record NutrientProfile(
            double calories,
            double protein,
            double carbohydrates,
            double fat,
            double sugar,
            double fiber,
            double sodium) {
    }

    private NutrientProfile resolveNutrientProfile(FoodVisionComponent component) {
        String type = component.componentType() == null ? "" : component.componentType().toLowerCase(Locale.ROOT);
        String name = component.name() == null ? "" : component.name().toLowerCase(Locale.ROOT);
        String beverageType = component.beverageType() == null ? "" : component.beverageType().toLowerCase(Locale.ROOT);

        if ("plain_water".equals(beverageType) || "water".equals(name) || "water".equals(type)) {
            return new NutrientProfile(0, 0, 0, 0, 0, 0, 0);
        }

        if ("drink".equals(type) || component.liquidVolumeMl() > 0) {
            if (name.contains("coffee") || name.contains("tea") || name.contains("herbal")) {
                if (name.contains("sweet") || name.contains("milk") || name.contains("latte")
                        || name.contains("sugar")) {
                    return new NutrientProfile(45, 1.2, 7.5, 1.2, 7.0, 0, 25);
                }
                return new NutrientProfile(5, 0.2, 0.8, 0.1, 0.2, 0, 5);
            }
            if (name.contains("juice") || name.contains("smoothie")) {
                return new NutrientProfile(48, 0.6, 11.5, 0.2, 9.5, 0.5, 5);
            }
            return new NutrientProfile(42, 0.4, 10.0, 0.2, 9.0, 0.1, 15);
        }

        if (type.contains("herb") || type.contains("vegetable") || type.contains("salad")
                || name.contains("herb") || name.contains("vegetable") || name.contains("salad")
                || name.contains("lettuce") || name.contains("cucumber") || name.contains("tomato")
                || name.contains("greens") || name.contains("spinach") || name.contains("cabbage")
                || name.contains("onion") || name.contains("garlic")) {
            return new NutrientProfile(25, 1.5, 4.5, 0.3, 1.8, 2.2, 15);
        }

        if (type.contains("condiment") || type.contains("sauce") || type.contains("dip") || type.contains("dressing")
                || name.contains("condiment") || name.contains("chili") || name.contains("sauce")
                || name.contains("paste") || name.contains("dressing") || name.contains("dip")) {
            return new NutrientProfile(45, 1.0, 7.0, 1.5, 4.5, 0.8, 650);
        }

        if (type.contains("meat") || type.contains("poultry") || type.contains("seafood") || type.contains("fish")
                || name.contains("meat") || name.contains("chicken") || name.contains("pork")
                || name.contains("beef") || name.contains("fish") || name.contains("egg")
                || name.contains("shrimp") || name.contains("duck") || name.contains("seafood")) {
            return new NutrientProfile(185, 22.0, 1.0, 10.5, 0.0, 0.0, 75);
        }

        if (type.contains("grain") || type.contains("rice") || type.contains("noodle")
                || name.contains("rice") || name.contains("noodle") || name.contains("bread")
                || name.contains("pasta") || name.contains("porridge") || name.contains("grain")) {
            return new NutrientProfile(130, 2.8, 28.0, 0.5, 0.2, 1.2, 5);
        }

        if (type.contains("fruit") || name.contains("fruit") || name.contains("banana")
                || name.contains("apple") || name.contains("mango") || name.contains("orange")) {
            return new NutrientProfile(60, 0.8, 15.0, 0.2, 12.0, 2.4, 2);
        }

        if (type.contains("soup") || type.contains("broth") || name.contains("soup") || name.contains("broth")) {
            return new NutrientProfile(35, 2.5, 3.0, 1.2, 1.0, 0.5, 350);
        }

        if (name.contains("fried") || name.contains("crispy") || name.contains("chip") || name.contains("snack")) {
            return new NutrientProfile(260, 7.0, 24.0, 15.0, 2.0, 1.8, 220);
        }

        if (name.contains("cake") || name.contains("dessert") || name.contains("sweet") || name.contains("cookie")) {
            return new NutrientProfile(320, 4.0, 48.0, 13.0, 26.0, 1.2, 140);
        }

        // Default balanced food profile
        return new NutrientProfile(120, 5.0, 15.0, 4.5, 2.5, 1.5, 120);
    }

    private double toApproximateGrams(double amount, String rawUnit) {
        if (!Double.isFinite(amount) || amount <= 0) {
            return 100.0;
        }
        if (rawUnit == null || rawUnit.isBlank()) {
            return amount >= 5 && amount <= 1000 ? amount : 100.0;
        }
        String unit = rawUnit.toLowerCase(Locale.ROOT).replace(".", "").trim();
        return switch (unit) {
            case "g", "gram", "grams" -> amount;
            case "kg", "kilogram", "kilograms" -> amount * 1_000;
            case "mg", "milligram", "milligrams" -> amount / 1_000;
            case "ml", "milliliter", "milliliters" -> amount;
            case "l", "liter", "liters" -> amount * 1_000;
            case "tablespoon", "tablespoons", "tbsp" -> amount * 15;
            case "teaspoon", "teaspoons", "tsp" -> amount * 5;
            case "piece", "pieces", "slice", "slices" -> amount * 40;
            case "cup", "cups" -> amount * 200;
            case "bowl", "bowls" -> amount * 280;
            case "plate", "plates", "serving", "servings" -> amount * 300;
            default -> amount >= 5 && amount <= 1000 ? amount : 100.0;
        };
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
                false, null, null, null, 0,
                0, 0, 0, 0, 0, 0, 0,
                NutritionSource.UNAVAILABLE, true);
    }

    private UnitAmount toBaseUnit(BigDecimal amount, String rawUnit) {
        if (rawUnit == null || rawUnit.isBlank())
            return null;
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
        if (nutrient == null)
            return 0;
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
