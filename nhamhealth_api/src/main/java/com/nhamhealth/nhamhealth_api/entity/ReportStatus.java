package com.nhamhealth.nhamhealth_api.entity;

public enum ReportStatus {
  PENDING,
  UNDER_REVIEW,
  ESCALATED,
  RESOLVED,
  NO_VIOLATION,
  REJECTED,
  /** Kept for records created before the mobile report workflow was added. */
  DISMISSED
}
