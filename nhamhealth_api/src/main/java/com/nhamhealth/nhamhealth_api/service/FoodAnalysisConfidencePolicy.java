package com.nhamhealth.nhamhealth_api.service;

import java.util.List;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import com.nhamhealth.nhamhealth_api.dto.ai.FoodCandidate;
import com.nhamhealth.nhamhealth_api.dto.ai.FoodVisionResult;
import com.nhamhealth.nhamhealth_api.dto.response.DetectedFoodComponent;
import com.nhamhealth.nhamhealth_api.dto.response.NutritionSource;

@Component
public class FoodAnalysisConfidencePolicy {
    private final double candidateThreshold;
    private final double candidateMarginThreshold;
    private final double portionThreshold;
    private final double componentThreshold;

    public FoodAnalysisConfidencePolicy(
            @Value("${app.ai.food.confirmation-threshold:0.75}") double candidateThreshold,
            @Value("${app.ai.food.candidate-margin-threshold:0.15}") double candidateMarginThreshold,
            @Value("${app.ai.food.portion-confirmation-threshold:0.70}") double portionThreshold,
            @Value("${app.ai.food.component-confirmation-threshold:0.65}") double componentThreshold) {
        this.candidateThreshold = candidateThreshold;
        this.candidateMarginThreshold = candidateMarginThreshold;
        this.portionThreshold = portionThreshold;
        this.componentThreshold = componentThreshold;
    }

    public boolean requiresCandidateConfirmation(
            double mealConfidence, List<FoodCandidate> candidates) {
        double top = candidates == null || candidates.isEmpty()
                ? mealConfidence : candidates.getFirst().confidence();
        if (top < candidateThreshold) return true;
        return candidates != null && candidates.size() > 1
                && top - candidates.get(1).confidence() < candidateMarginThreshold;
    }

    public boolean requiresConfirmation(
            FoodVisionResult vision, List<DetectedFoodComponent> components) {
        if (!vision.foodDetected() || components == null || components.isEmpty()) return true;
        if (requiresCandidateConfirmation(vision.mealConfidence(), vision.candidates())) return true;
        if (vision.portionConfidence() < portionThreshold) return true;
        return components.stream().anyMatch(component ->
                component.confidence() < componentThreshold
                        || component.portionConfidence() < portionThreshold
                        || component.requiresUserConfirmation()
                        || component.nutritionSource() != NutritionSource.DATABASE_CALCULATED);
    }
}
