package com.nhamhealth.nhamhealth_api.dto.response;

import com.nhamhealth.nhamhealth_api.entity.*;
import java.time.LocalDateTime;
import java.util.List;

public record AdminReportResponse(
    Integer id,
    ReportType type,
    Integer targetId,
    ReportReasonCode reason,
    String description,
    ReportStatus status,
    ReportSeverity severity,
    LocalDateTime createdAt,
    Integer reporterId,
    String reporterName,
    Integer reportedUserId,
    String reportedUserName,
    String targetSummary,
    String contentSnapshot,
    long previousReportCount,
    List<ModerationActionResponse> moderationHistory,
    String adminNote) {}
