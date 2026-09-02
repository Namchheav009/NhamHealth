package com.nhamhealth.nhamhealth_api.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record VerifyPasswordResetCodeRequest(
        @NotBlank(message = "Email is required")
        @Email(message = "Email must be valid")
        String email,

        @NotBlank(message = "Verification code is required")
        @Pattern(regexp = "\\d{4}", message = "Verification code must contain four digits")
        String code) {
    @Override public String toString() { return "VerifyPasswordResetCodeRequest[email=" + email + ", code=[REDACTED]]"; }
}
