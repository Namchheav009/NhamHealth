package com.nhamhealth.nhamhealth_api.dto.request;

import java.math.BigDecimal;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record AdminServingSizeRequest(
        @NotBlank(message = "Serving-size name is required")
        @Size(max = 50, message = "Serving-size name must not exceed 50 characters")
        String servingSizeName,
        @NotNull(message = "Multiplier is required")
        @DecimalMin(value = "0.0001", message = "Multiplier must be greater than zero")
        @Digits(integer = 10, fraction = 4, message = "Multiplier must have at most 10 whole digits and 4 decimals")
        BigDecimal multiplier,
        @Size(max = 255, message = "Description must not exceed 255 characters")
        String description,
        Boolean active) {
}
