package com.nhamhealth.nhamhealth_api.service.ai;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;

import org.junit.jupiter.api.Test;

import com.nhamhealth.nhamhealth_api.dto.ai.FoodCandidate;

class FoodAnalysisConfidencePolicyTests {
    private final FoodAnalysisConfidencePolicy policy =
            new FoodAnalysisConfidencePolicy(0.75, 0.15, 0.70, 0.65);

    @Test
    void acceptsStrongCandidateWithLargeMargin() {
        assertFalse(policy.requiresCandidateConfirmation(
                0.82,
                List.of(new FoodCandidate("A", 0.82), new FoodCandidate("B", 0.10))));
    }

    @Test
    void requiresConfirmationBelowCandidateThreshold() {
        assertTrue(policy.requiresCandidateConfirmation(
                0.62,
                List.of(new FoodCandidate("A", 0.62), new FoodCandidate("B", 0.27))));
    }

    @Test
    void requiresConfirmationWhenCandidateMarginIsSmall() {
        assertTrue(policy.requiresCandidateConfirmation(
                0.80,
                List.of(new FoodCandidate("A", 0.80), new FoodCandidate("B", 0.71))));
    }
}
