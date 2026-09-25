package com.nhamhealth.nhamhealth_api.dto.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record MealPlanFeedbackRequest(
        @Min(1) @Max(5) Short rating,
        @NotBlank String outcome,
        @Size(max = 80) String skipReason,
        @Min(1) @Max(5) Short hungerBefore,
        @Min(1) @Max(5) Short fullnessAfter,
        @Size(max = 500) String comment) {
}
