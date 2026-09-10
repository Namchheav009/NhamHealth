package com.nhamhealth.nhamhealth_api.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "moderation_appeals")
public class ModerationAppeal {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  @Column(name = "appeal_id")
  private Integer appealId;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "moderation_action_id", nullable = false)
  private ModerationAction moderationAction;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "user_id", nullable = false)
  private User user;

  @Column(nullable = false, length = 500)
  private String reason;

  @Enumerated(EnumType.STRING)
  @Column(nullable = false, length = 20)
  private AppealStatus status;

  @Column(name = "admin_note", length = 1000)
  private String adminNote;

  @Column(name = "created_at", nullable = false)
  private LocalDateTime createdAt;

  @Column(name = "reviewed_at")
  private LocalDateTime reviewedAt;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "reviewed_by")
  private User reviewedBy;

  @PrePersist
  void create() {
    if (createdAt == null) createdAt = LocalDateTime.now();
    if (status == null) status = AppealStatus.PENDING;
  }

  public Integer getAppealId() {
    return appealId;
  }

  public ModerationAction getModerationAction() {
    return moderationAction;
  }

  public void setModerationAction(ModerationAction v) {
    moderationAction = v;
  }

  public User getUser() {
    return user;
  }

  public void setUser(User v) {
    user = v;
  }

  public String getReason() {
    return reason;
  }

  public void setReason(String v) {
    reason = v;
  }

  public AppealStatus getStatus() {
    return status;
  }

  public void setStatus(AppealStatus v) {
    status = v;
  }

  public String getAdminNote() {
    return adminNote;
  }

  public void setAdminNote(String v) {
    adminNote = v;
  }

  public LocalDateTime getCreatedAt() {
    return createdAt;
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
}
