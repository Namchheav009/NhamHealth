package com.nhamhealth.nhamhealth_api.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RegisterRequest(
        @NotBlank(message = "Full name is required")
        @Size(min = 2, max = 150, message = "Full name must contain between 2 and 150 characters")
        String fullName,

        @NotBlank(message = "Email or phone number is required")
        String email,

        @NotBlank(message = "Password is required")
        @Size(min = 8, max = 72, message = "Password must contain between 8 and 72 characters")
        String password) {

    @Override
    public String toString() {
        return "RegisterRequest[email=" + email + ", password=[REDACTED]]";
    }
}
