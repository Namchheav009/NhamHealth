package com.nhamhealth.nhamhealth_api.dto.request;

import com.nhamhealth.nhamhealth_api.entity.*;
import jakarta.validation.constraints.*;

public record CreateReportRequest(
    @NotNull ReportType reportType,
    @NotNull Integer targetId,
    @NotNull ReportReasonCode reason,
    @Size(max = 500) String description) {}
