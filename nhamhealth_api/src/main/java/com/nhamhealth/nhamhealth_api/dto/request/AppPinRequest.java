package com.nhamhealth.nhamhealth_api.dto.request;

import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.NotNull;

public record AppPinRequest(
        @NotNull(message = "PIN is required")
        @Pattern(regexp = "\\d{6}", message = "PIN must contain exactly 6 digits")
        String pin) {
}
