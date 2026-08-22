package com.nhamhealth.nhamhealth_api.dto.request;

import java.math.BigDecimal;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record AiFoodFeedbackRequest(
        @NotNull Boolean confirmed,
        @NotBlank @Size(max = 150) String foodName,
        @NotNull @DecimalMin("0.01") @DecimalMax("10000") BigDecimal servingSize,
        @NotBlank @Size(max = 40) String servingUnit) {
}
