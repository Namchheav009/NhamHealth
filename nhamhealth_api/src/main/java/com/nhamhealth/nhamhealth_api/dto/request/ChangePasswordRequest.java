package com.nhamhealth.nhamhealth_api.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ChangePasswordRequest(
        @NotBlank(message = "Current password is required")
        String currentPassword,

        @NotBlank(message = "New password is required")
        @Size(min = 8, max = 72, message = "New password must contain between 8 and 72 characters")
        String newPassword) {
    @Override public String toString() { return "ChangePasswordRequest[currentPassword=[REDACTED], newPassword=[REDACTED]]"; }
}
