package com.nhamhealth.nhamhealth_api.dto.response;

import java.time.LocalDateTime;

public record NotificationResponse(
        Integer id,
        String type,
        String title,
        String message,
        Integer actorUserId,
        String actorAvatarUrl,
        String referenceType,
        Integer referenceId,
        boolean read,
        LocalDateTime createdAt) {
}
