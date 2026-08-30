package com.nhamhealth.nhamhealth_api.service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

import org.springframework.stereotype.Component;

import com.nhamhealth.nhamhealth_api.dto.ai.FoodCandidate;
import com.nhamhealth.nhamhealth_api.dto.ai.FoodVisionComponent;
import com.nhamhealth.nhamhealth_api.dto.ai.FoodVisionResult;

@Component
public class FoodVisionResultValidator {
    private static final int MAX_COMPONENTS = 20;
    private static final int MAX_CANDIDATES = 3;
    private static final double MAX_PORTION_AMOUNT = 100_000;
    private static final Set<String> SUPPORTED_UNITS = Set.of(
            "g", "kg", "mg", "ml", "l", "piece", "slice", "bowl", "cup",
            "plate", "serving", "tablespoon", "teaspoon");
    private static final Set<String> BEVERAGE_TYPES = Set.of(
            "plain_water", "coffee_tea", "juice_smoothie", "dairy",
            "soft_drink", "alcohol", "other", "none");

    public FoodVisionResult validateAndNormalize(FoodVisionResult value) {
        if (value == null) throw invalid("The vision response was empty.");
        if (!value.foodDetected()) {
            return new FoodVisionResult(
                    false,
                    textOrDefault(value.reason(), "No food or drink was clearly visible.", 300),
                    "Unknown food",
                    "Unknown",
                    "food",
                    0, 0, 0,
                    List.of(), List.of());
        }

        String mealName = requiredText(value.mealName(), "mealName", 150);
        double mealConfidence = confidence(value.mealConfidence(), "mealConfidence");
        double portionConfidence = confidence(value.portionConfidence(), "portionConfidence");
        double preparationConfidence = confidence(
                value.preparationConfidence(), "preparationConfidence");
        String type = normalizeType(value.type());
        String cuisine = textOrDefault(value.cuisine(), "Unknown", 80);

        List<FoodVisionComponent> rawComponents = value.components();
        if (rawComponents == null || rawComponents.isEmpty()) {
            throw invalid("A detected meal must contain at least one visible component.");
        }
        if (rawComponents.size() > MAX_COMPONENTS) {
            throw invalid("The vision response contains too many components.");
        }
        List<FoodVisionComponent> components = new ArrayList<>(rawComponents.size());
        Set<String> componentNames = new HashSet<>();
        for (FoodVisionComponent component : rawComponents) {
            if (component == null) throw invalid("A vision component was null.");
            double amount = component.estimatedAmount();
            if (!Double.isFinite(amount) || amount <= 0 || amount > MAX_PORTION_AMOUNT) {
                throw invalid("A component amount was outside the supported range.");
            }
            String componentName = requiredText(component.name(), "component.name", 150);
            if (!componentNames.add(componentName.toLowerCase(Locale.ROOT))) {
                throw invalid("Duplicate component name: " + componentName);
            }
            String unit = normalizeUnit(component.unit());
            String componentType = normalizeComponentType(
                    component.componentType(), type, componentName, unit);
            double liquidVolumeMl = normalizeLiquidVolume(
                    component.liquidVolumeMl(), component.estimatedAmount(), unit, componentType);
            String beverageType = normalizeBeverageType(
                    component.beverageType(), componentType, componentName);
            components.add(new FoodVisionComponent(
                    componentName,
                    amount,
                    unit,
                    confidence(component.confidence(), "component.confidence"),
                    confidence(component.portionConfidence(), "component.portionConfidence"),
                    textOrDefault(component.preparationMethod(), "unknown", 80),
                    requiredText(component.visibleEvidence(), "component.visibleEvidence", 300),
                    componentType,
                    liquidVolumeMl,
                    beverageType));
        }

        List<FoodCandidate> candidates = normalizeCandidates(
                value.candidates(), mealName, mealConfidence);
        if (candidates.isEmpty()) {
            candidates = List.of(new FoodCandidate(mealName, mealConfidence));
        }
        if (!candidates.getFirst().name().equalsIgnoreCase(mealName)) {
            throw invalid("mealName must match the highest-confidence candidate.");
        }
        double candidateConfidence = candidates.getFirst().confidence();
        if (Math.abs(candidateConfidence - mealConfidence) > 0.05) {
            throw invalid("mealConfidence must match the highest-confidence candidate.");
        }
        mealConfidence = candidateConfidence;
        return new FoodVisionResult(
                true,
                textOrDefault(value.reason(), "", 300),
                mealName,
                cuisine,
                type,
                mealConfidence,
                portionConfidence,
                preparationConfidence,
                List.copyOf(components),
                candidates);
    }

    private List<FoodCandidate> normalizeCandidates(
            List<FoodCandidate> values, String mealName, double mealConfidence) {
        List<FoodCandidate> normalized = new ArrayList<>();
        Set<String> seen = new HashSet<>();
        if (values != null) {
            for (FoodCandidate value : values) {
                if (value == null) continue;
                String name = requiredText(value.name(), "candidate.name", 150);
                double score = confidence(value.confidence(), "candidate.confidence");
                if (seen.add(name.toLowerCase(Locale.ROOT))) {
                    normalized.add(new FoodCandidate(name, score));
                }
            }
        }
        if (seen.add(mealName.toLowerCase(Locale.ROOT))) {
            normalized.add(new FoodCandidate(mealName, mealConfidence));
        }
        normalized.sort(Comparator.comparingDouble(FoodCandidate::confidence).reversed());
        return List.copyOf(normalized.subList(0, Math.min(MAX_CANDIDATES, normalized.size())));
    }

    private String normalizeUnit(String value) {
        String unit = requiredText(value, "component.unit", 40)
                .toLowerCase(Locale.ROOT)
                .replaceAll("[.]", "")
                .trim();
        unit = switch (unit) {
            case "gram", "grams" -> "g";
            case "kilogram", "kilograms" -> "kg";
            case "milligram", "milligrams" -> "mg";
            case "milliliter", "milliliters", "millilitre", "millilitres" -> "ml";
            case "liter", "liters", "litre", "litres" -> "l";
            case "pieces" -> "piece";
            case "slices" -> "slice";
            case "bowls" -> "bowl";
            case "cups" -> "cup";
            case "plates" -> "plate";
            case "servings" -> "serving";
            case "tbsp", "tablespoons" -> "tablespoon";
            case "tsp", "teaspoons" -> "teaspoon";
            default -> unit;
        };
        if (!SUPPORTED_UNITS.contains(unit)) {
            throw invalid("Unsupported component unit: " + unit);
        }
        return unit;
    }

    private String normalizeType(String value) {
        if (value == null) return "food";
        return switch (value.trim().toLowerCase(Locale.ROOT)) {
            case "drink", "beverage" -> "drink";
            case "mixed", "food and drink", "food+drink" -> "mixed";
            default -> "food";
        };
    }

    private String normalizeComponentType(
            String value, String mealType, String name, String unit) {
        if (value != null) {
            String normalized = value.trim().toLowerCase(Locale.ROOT);
            if ("drink".equals(normalized) || "beverage".equals(normalized)) return "drink";
            if ("food".equals(normalized)) return "food";
        }
        if ("drink".equals(mealType)) return "drink";
        if ("food".equals(mealType)) return "food";
        if (Set.of("ml", "l", "cup").contains(unit)) return "drink";
        String normalizedName = name.toLowerCase(Locale.ROOT);
        return normalizedName.matches(".*\\b(water|drink|beverage|juice|smoothie|shake|coffee|tea|soda)\\b.*")
                ? "drink" : "food";
    }

    private double normalizeLiquidVolume(
            double supplied, double amount, String unit, String componentType) {
        if (!"drink".equals(componentType)) return 0;
        if (Double.isFinite(supplied) && supplied > 0 && supplied <= MAX_PORTION_AMOUNT) {
            return Math.round(supplied);
        }
        double converted = switch (unit) {
            case "ml" -> amount;
            case "l" -> amount * 1_000;
            case "cup" -> amount * 240;
            case "tablespoon" -> amount * 15;
            case "teaspoon" -> amount * 5;
            default -> 0;
        };
        if (!Double.isFinite(converted) || converted < 0 || converted > MAX_PORTION_AMOUNT) {
            throw invalid("A drink liquid volume was outside the supported range.");
        }
        return Math.round(converted);
    }

    private String normalizeBeverageType(
            String value, String componentType, String componentName) {
        if (!"drink".equals(componentType)) return "none";
        String normalized = value == null ? "" : value.trim().toLowerCase(Locale.ROOT);
        if (BEVERAGE_TYPES.contains(normalized) && !"none".equals(normalized)) {
            if (!"plain_water".equals(normalized) || isWaterName(componentName)) return normalized;
        }
        return isWaterName(componentName) ? "plain_water" : "other";
    }

    private boolean isWaterName(String value) {
        String name = value.toLowerCase(Locale.ROOT).replace('-', ' ').trim();
        return name.matches("(plain |drinking |still |sparkling |mineral |bottled )*water");
    }

    private double confidence(double value, String field) {
        if (!Double.isFinite(value) || value < 0 || value > 1) {
            throw invalid(field + " must be between 0 and 1.");
        }
        return value;
    }

    private String requiredText(String value, String field, int maximum) {
        if (value == null || value.isBlank()) throw invalid(field + " is required.");
        String trimmed = value.trim();
        if (trimmed.length() > maximum) throw invalid(field + " is too long.");
        return trimmed;
    }

    private String textOrDefault(String value, String fallback, int maximum) {
        if (value == null || value.isBlank()) return fallback;
        String trimmed = value.trim();
        return trimmed.length() <= maximum ? trimmed : trimmed.substring(0, maximum);
    }

    private IllegalArgumentException invalid(String message) {
        return new IllegalArgumentException("Invalid food vision JSON: " + message);
    }
}
