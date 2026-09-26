package com.nhamhealth.nhamhealth_api.dto.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record MealPlanFeedbackRequest(
        @Min(1) @Max(5) Short rating,
        @NotBlank @Size(max = 50) String outcome,
        @Size(max = 80) String skipReason,
        @Min(1) @Max(5) Short hungerBefore,
        @Min(1) @Max(5) Short fullnessAfter,
        @Size(max = 500) String comment) {

    public MealPlanFeedbackRequest {
        outcome = outcome != null ? outcome.trim() : null;
        skipReason = skipReason != null ? skipReason.trim() : null;
        comment = comment != null ? comment.trim() : null;
        if (skipReason != null && skipReason.isBlank()) {
            skipReason = null;
        }
        if (comment != null && comment.isBlank()) {
            comment = null;
        }
    }
}
