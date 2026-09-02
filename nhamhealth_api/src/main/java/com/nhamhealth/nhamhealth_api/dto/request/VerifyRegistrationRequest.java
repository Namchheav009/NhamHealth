package com.nhamhealth.nhamhealth_api.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record VerifyRegistrationRequest(
        @NotBlank @Email String email,
        @NotBlank @Pattern(regexp = "\\d{4}", message = "Code must contain 4 digits") String code) {
    @Override public String toString() { return "VerifyRegistrationRequest[email=" + email + ", code=[REDACTED]]"; }
}
