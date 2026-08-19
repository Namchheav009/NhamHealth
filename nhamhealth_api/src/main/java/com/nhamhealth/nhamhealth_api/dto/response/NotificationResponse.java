package com.nhamhealth.nhamhealth_api.dto.response;

import java.time.LocalDateTime;

public record NotificationResponse(
        Integer id,
        String type,
        String title,
        String message,
        boolean read,
        LocalDateTime createdAt) {
}
