package com.nhamhealth.nhamhealth_api.dto.response;

import com.nhamhealth.nhamhealth_api.entity.AppealStatus;
import java.time.LocalDateTime;

public record AppealResponse(
    Integer id,
    Integer actionId,
    Integer userId,
    String reason,
    AppealStatus status,
    String adminNote,
    LocalDateTime createdAt,
    LocalDateTime reviewedAt) {}
