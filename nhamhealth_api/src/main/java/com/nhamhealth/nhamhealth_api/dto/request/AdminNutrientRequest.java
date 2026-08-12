package com.nhamhealth.nhamhealth_api.dto.request;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record AdminNutrientRequest(
        @NotBlank @Size(max = 50) String nutrientName,
        @NotBlank @Size(max = 20) String unit,
        @NotNull Boolean core,
        @NotNull Boolean active,
        @NotNull @Min(1) Integer displayOrder) {
}
