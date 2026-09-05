package com.nhamhealth.nhamhealth_api.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record VerifyRegistrationRequest(
        @NotBlank(message = "Email or phone number is required")
        String email,

        @NotBlank(message = "Code is required")
        @Pattern(regexp = "\\d{6}", message = "Code must contain 6 digits")
        String code) {

    @Override
    public String toString() {
        return "VerifyRegistrationRequest[email=" + email + ", code=[REDACTED]]";
    }
}
