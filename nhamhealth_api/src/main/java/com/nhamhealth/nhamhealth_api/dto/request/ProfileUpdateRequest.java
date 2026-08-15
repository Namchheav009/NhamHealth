package com.nhamhealth.nhamhealth_api.dto.request;

import java.math.BigDecimal;
import java.time.LocalDate;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Past;
import jakarta.validation.constraints.Size;

public record ProfileUpdateRequest(
        @NotBlank @Size(max = 150) String fullName,
        @NotBlank @Email @Size(max = 150) String email,
        @Size(max = 30) String phone,
        @Past LocalDate dateOfBirth,
        @Size(max = 30) String gender,
        @DecimalMin("50.0") @DecimalMax("300.0") BigDecimal heightCm,
        @DecimalMin("15.0") @DecimalMax("500.0") BigDecimal weightKg) {
}
