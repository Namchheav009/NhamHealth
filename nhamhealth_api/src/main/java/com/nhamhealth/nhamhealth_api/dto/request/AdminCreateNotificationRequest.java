package com.nhamhealth.nhamhealth_api.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record AdminCreateNotificationRequest(
        @NotBlank(message = "User email is required")
        @Email(message = "User email must be valid")
        String userEmail,
        @NotBlank(message = "Title is required")
        @Size(max = 150, message = "Title must not exceed 150 characters")
        String title,
        @NotBlank(message = "Message is required")
        @Size(max = 500, message = "Message must not exceed 500 characters")
        String message,
        @NotBlank(message = "Notification type is required")
        @Size(max = 50, message = "Notification type must not exceed 50 characters")
        String notificationType) {
}
