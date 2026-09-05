package com.nhamhealth.nhamhealth_api.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record VerifyPasswordResetCodeRequest(
        @NotBlank(message = "Email or phone number is required")
        String email,
        @NotBlank(message = "Verification code is required")
        @Pattern(regexp = "\\d{6}", message = "Verification code must contain six digits")
        String code) {

    @Override
    public String toString() {
        return "VerifyPasswordResetCodeRequest[email=" + email + ", code=[REDACTED]]";
    }
}
