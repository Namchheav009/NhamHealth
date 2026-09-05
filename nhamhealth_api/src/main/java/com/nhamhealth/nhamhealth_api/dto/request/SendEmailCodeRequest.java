package com.nhamhealth.nhamhealth_api.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record SendEmailCodeRequest(
        @NotBlank(message = "Email address is required")
        @Email(message = "Email must be valid")
        String email) {
}
