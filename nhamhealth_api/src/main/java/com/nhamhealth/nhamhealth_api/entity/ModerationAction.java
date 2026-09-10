package com.nhamhealth.nhamhealth_api.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "moderation_actions")
public class ModerationAction {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  @Column(name = "action_id")
  private Integer actionId;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "report_id")
  private Report report;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "target_user_id", nullable = false)
  private User targetUser;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "admin_user_id", nullable = false)
  private User adminUser;

  @Enumerated(EnumType.STRING)
  @Column(name = "action_type", nullable = false, length = 30)
  private ModerationActionType actionType;

  @Enumerated(EnumType.STRING)
  @Column(nullable = false, length = 60)
  private ReportReasonCode reason;

  @Column(name = "admin_note", length = 1000)
  private String adminNote;

  @Column(name = "starts_at")
  private LocalDateTime startsAt;

  @Column(name = "expires_at")
  private LocalDateTime expiresAt;

  @Column(name = "created_at", nullable = false)
  private LocalDateTime createdAt;

  @Column(name = "reversed_at")
  private LocalDateTime reversedAt;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "reversed_by")
  private User reversedBy;

  @PrePersist
  void create() {
    if (createdAt == null) createdAt = LocalDateTime.now();
  }

  public Integer getActionId() {
    return actionId;
  }

  public Report getReport() {
    return report;
  }

  public void setReport(Report v) {
    report = v;
  }

  public User getTargetUser() {
    return targetUser;
  }

  public void setTargetUser(User v) {
    targetUser = v;
  }

  public User getAdminUser() {
    return adminUser;
  }

  public void setAdminUser(User v) {
    adminUser = v;
  }

  public ModerationActionType getActionType() {
    return actionType;
  }

  public void setActionType(ModerationActionType v) {
    actionType = v;
  }

  public ReportReasonCode getReason() {
    return reason;
  }

  public void setReason(ReportReasonCode v) {
    reason = v;
  }

  public String getAdminNote() {
    return adminNote;
  }

  public void setAdminNote(String v) {
    adminNote = v;
  }

  public LocalDateTime getStartsAt() {
    return startsAt;
  }

  public void setStartsAt(LocalDateTime v) {
    startsAt = v;
  }

  public LocalDateTime getExpiresAt() {
    return expiresAt;
  }

  public void setExpiresAt(LocalDateTime v) {
    expiresAt = v;
  }

  public LocalDateTime getCreatedAt() {
    return createdAt;
  }

  public LocalDateTime getReversedAt() {
    return reversedAt;
  }

  public void setReversedAt(LocalDateTime v) {
    reversedAt = v;
  }

  public User getReversedBy() {
    return reversedBy;
  }

  public void setReversedBy(User v) {
    reversedBy = v;
  }
}
