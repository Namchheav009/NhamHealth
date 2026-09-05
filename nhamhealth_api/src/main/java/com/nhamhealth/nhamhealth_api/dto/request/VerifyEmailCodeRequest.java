package com.nhamhealth.nhamhealth_api.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record VerifyEmailCodeRequest(
        @NotBlank(message = "Email address is required")
        @Email(message = "Email must be valid")
        String email,
        @NotBlank(message = "Verification code is required")
        @Pattern(regexp = "\\d{6}", message = "Verification code must contain six digits")
        String code) {
}
