package com.nhamhealth.nhamhealth_api.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "reports")
public class Report {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  @Column(name = "report_id")
  private Integer reportId;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "reporter_user_id", nullable = false)
  private User reporter;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "reported_user_id", nullable = false)
  private User reportedUser;

  @Enumerated(EnumType.STRING)
  @Column(name = "report_type", nullable = false, length = 20)
  private ReportType reportType;

  @Column(name = "target_id", nullable = false)
  private Integer targetId;

  @Enumerated(EnumType.STRING)
  @Column(nullable = false, length = 60)
  private ReportReasonCode reason;

  @Column(length = 500)
  private String description;

  @Column(name = "content_snapshot", length = 1000)
  private String contentSnapshot;

  @Enumerated(EnumType.STRING)
  @Column(nullable = false, length = 20)
  private ReportStatus status;

  @Enumerated(EnumType.STRING)
  @Column(nullable = false, length = 20)
  private ReportSeverity severity;

  @Column(name = "created_at", nullable = false, updatable = false)
  private LocalDateTime createdAt;

  @Column(name = "updated_at", nullable = false)
  private LocalDateTime updatedAt;

  @Column(name = "reviewed_at")
  private LocalDateTime reviewedAt;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "reviewed_by")
  private User reviewedBy;

  @Column(name = "admin_note", length = 1000)
  private String adminNote;

  @Column(name = "admin_message", length = 1000)
  private String adminMessage;

  @PrePersist
  void create() {
    var now = LocalDateTime.now();
    if (createdAt == null) createdAt = now;
    updatedAt = now;
    if (status == null) status = ReportStatus.PENDING;
    if (severity == null) severity = ReportSeverity.MEDIUM;
  }

  @PreUpdate
  void update() {
    updatedAt = LocalDateTime.now();
  }

  public Integer getReportId() {
    return reportId;
  }

  public User getReporter() {
    return reporter;
  }

  public void setReporter(User v) {
    reporter = v;
  }

  public User getReportedUser() {
    return reportedUser;
  }

  public void setReportedUser(User v) {
    reportedUser = v;
  }

  public ReportType getReportType() {
    return reportType;
  }

  public void setReportType(ReportType v) {
    reportType = v;
  }

  public Integer getTargetId() {
    return targetId;
  }

  public void setTargetId(Integer v) {
    targetId = v;
  }

  public ReportReasonCode getReason() {
    return reason;
  }

  public void setReason(ReportReasonCode v) {
    reason = v;
  }

  public String getDescription() {
    return description;
  }

  public void setDescription(String v) {
    description = v;
  }

  public String getContentSnapshot() {
    return contentSnapshot;
  }

  public void setContentSnapshot(String v) {
    contentSnapshot = v;
  }

  public ReportStatus getStatus() {
    return status;
  }

  public void setStatus(ReportStatus v) {
    status = v;
  }

  public ReportSeverity getSeverity() {
    return severity;
  }

  public void setSeverity(ReportSeverity v) {
    severity = v;
  }

  public LocalDateTime getCreatedAt() {
    return createdAt;
  }

  public LocalDateTime getUpdatedAt() {
    return updatedAt;
  }

  public LocalDateTime getReviewedAt() {
    return reviewedAt;
  }

  public void setReviewedAt(LocalDateTime v) {
    reviewedAt = v;
  }

  public User getReviewedBy() {
    return reviewedBy;
  }

  public void setReviewedBy(User v) {
    reviewedBy = v;
  }

  public String getAdminNote() {
    return adminNote;
  }

  public void setAdminNote(String v) {
    adminNote = v;
  }

  public String getAdminMessage() { return adminMessage; }
  public void setAdminMessage(String value) { adminMessage = value; }
}
