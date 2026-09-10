package com.nhamhealth.nhamhealth_api.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record AdminCreateNotificationRequest(
        @NotBlank(message = "User email or ALL is required") @Pattern(regexp = "^(?i:ALL|[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,})$", message = "Must be a valid email or ALL") String userEmail,
        @NotBlank(message = "Title is required") @Size(max = 150, message = "Title must not exceed 150 characters") String title,
        @NotBlank(message = "Message is required") @Size(max = 500, message = "Message must not exceed 500 characters") String message,
        @NotBlank(message = "Notification type is required") @Size(max = 50, message = "Notification type must not exceed 50 characters") String notificationType,
        String avatarUrl,
        String subText) {
    public AdminCreateNotificationRequest(String userEmail, String title, String message, String notificationType) {
        this(userEmail, title, message, notificationType, null, null);
    }
}
