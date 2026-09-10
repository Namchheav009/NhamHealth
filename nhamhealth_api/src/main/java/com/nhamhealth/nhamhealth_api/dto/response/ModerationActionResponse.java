package com.nhamhealth.nhamhealth_api.dto.response;

import com.nhamhealth.nhamhealth_api.entity.*;
import java.time.LocalDateTime;

public record ModerationActionResponse(
    Integer id,
    Integer reportId,
    Integer targetUserId,
    String admin,
    ModerationActionType actionType,
    ReportReasonCode reason,
    String adminNote,
    LocalDateTime startsAt,
    LocalDateTime expiresAt,
    LocalDateTime createdAt,
    boolean reversed) {}
