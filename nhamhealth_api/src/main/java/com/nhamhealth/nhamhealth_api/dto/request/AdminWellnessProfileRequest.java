package com.nhamhealth.nhamhealth_api.dto.request;

import java.math.BigDecimal;
import java.time.LocalDate;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Past;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record AdminWellnessProfileRequest(
        @NotBlank(message = "User email is required")
        @Email(message = "User email must be valid")
        String userEmail,

        @Size(max = 255, message = "Profile image URL must not exceed 255 characters")
        String profileImageUrl,

        @Size(max = 30, message = "Gender must not exceed 30 characters")
        String gender,

        @Past(message = "Date of birth must be in the past")
        LocalDate dateOfBirth,

        @NotNull(message = "Height is required")
        @DecimalMin(value = "50.0", message = "Height must be at least 50 cm")
        @DecimalMax(value = "300.0", message = "Height must not exceed 300 cm")
        BigDecimal heightCm,

        @NotNull(message = "Weight is required")
        @DecimalMin(value = "15.0", message = "Weight must be at least 15 kg")
        @DecimalMax(value = "500.0", message = "Weight must not exceed 500 kg")
        BigDecimal weightKg,

        @NotBlank(message = "Activity level is required")
        @Pattern(regexp = "(?i)LOW|MODERATE|HIGH", message = "Activity level must be LOW, MODERATE, or HIGH")
        String activityLevel) {
}
