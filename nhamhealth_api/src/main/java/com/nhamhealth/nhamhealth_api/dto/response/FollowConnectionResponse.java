package com.nhamhealth.nhamhealth_api.dto.response;

import java.time.LocalDateTime;

public record FollowConnectionResponse(
        Integer id,
        Integer senderId,
        Integer receiverId,
        String status,
        String relationshipStatus,
        LocalDateTime createdAt,
        LocalDateTime respondedAt) { }
