package com.nhamhealth.nhamhealth_api.dto.response;

import com.nhamhealth.nhamhealth_api.entity.*;
import java.time.LocalDateTime;

public record ReportResponse(
    Integer id,
    ReportType type,
    Integer targetId,
    ReportReasonCode reason,
    String description,
    ReportStatus status,
    ReportSeverity severity,
    LocalDateTime createdAt,
    LocalDateTime updatedAt) {
        
    }
