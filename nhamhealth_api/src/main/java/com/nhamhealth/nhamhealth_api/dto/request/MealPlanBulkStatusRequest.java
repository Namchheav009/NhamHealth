package com.nhamhealth.nhamhealth_api.dto.request;

import java.util.List;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record MealPlanBulkStatusRequest(
        @NotEmpty @Size(max = 28) List<@NotNull Integer> planIds,
        @NotBlank String status) {
}
