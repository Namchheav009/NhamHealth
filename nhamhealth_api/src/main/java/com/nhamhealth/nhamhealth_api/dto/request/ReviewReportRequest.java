package com.nhamhealth.nhamhealth_api.dto.request;

import com.nhamhealth.nhamhealth_api.entity.ReportSeverity;
import jakarta.validation.constraints.Size;

public record ReviewReportRequest(
    @Size(max = 1000) String adminNote,
    ReportSeverity severity,
    @Size(max = 1000) String adminMessage) {
  public ReviewReportRequest(String adminNote, ReportSeverity severity) {
    this(adminNote, severity, null);
  }
}
