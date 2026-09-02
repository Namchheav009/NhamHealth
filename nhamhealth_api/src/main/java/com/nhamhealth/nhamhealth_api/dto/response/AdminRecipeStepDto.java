package com.nhamhealth.nhamhealth_api.dto.response;

public record AdminRecipeStepDto(
        Integer stepId,
        Integer stepNumber,
        String instruction) {
}
