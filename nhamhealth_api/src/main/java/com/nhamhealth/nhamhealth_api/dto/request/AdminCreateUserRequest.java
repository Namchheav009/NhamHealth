package com.nhamhealth.nhamhealth_api.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record AdminCreateUserRequest(
        @NotBlank(message = "Full name is required")
        @Size(min = 2, max = 150, message = "Full name must contain between 2 and 150 characters")
        String fullName,

        @NotBlank(message = "Email is required")
        @Email(message = "Email must be valid")
        String email,

        @Size(max = 255, message = "Profile image URL must not exceed 255 characters")
        String profileImageUrl,

        @NotBlank(message = "A temporary password is required")
        @Size(min = 8, max = 72, message = "Password must contain between 8 and 72 characters")
        String password,

        @NotBlank(message = "Role is required")
        @Pattern(regexp = "(?i)USER|ADMIN", message = "Role must be USER or ADMIN")
        String role,

        @Pattern(regexp = "(?i)ACTIVE|PENDING|SUSPENDED|BANNED", message = "Status must be ACTIVE, PENDING, SUSPENDED, or BANNED")
        String status,

        Boolean verified) {
}
