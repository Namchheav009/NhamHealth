package com.nhamhealth.nhamhealth_api.dto.request;

import com.nhamhealth.nhamhealth_api.entity.ReportReasonCode;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record CreatePostReportRequest(
    @NotNull ReportReasonCode reason,
    @Size(max = 500) String description) {}
