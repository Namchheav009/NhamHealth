package com.nhamhealth.nhamhealth_api.service.community;

import static org.springframework.http.HttpStatus.BAD_REQUEST;

import com.nhamhealth.nhamhealth_api.entity.ModerationActionType;
import com.nhamhealth.nhamhealth_api.entity.ReportReasonCode;
import com.nhamhealth.nhamhealth_api.entity.ReportSeverity;
import com.nhamhealth.nhamhealth_api.entity.ReportType;
import java.util.Set;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;

/** Centralizes target-specific moderation rules so API and service flows stay consistent. */
@Component
public class ReportModerationPolicy {

  public void requireAllowedReason(ReportType type, ReportReasonCode reason) {
    if (!reasonsFor(type).contains(reason)) {
      throw new ResponseStatusException(
          BAD_REQUEST, "Invalid report reason for " + type.name().toLowerCase());
    }
  }

  public void requireAllowedAction(ReportType type, ModerationActionType action) {
    if (!actionsFor(type).contains(action)) {
      throw new ResponseStatusException(BAD_REQUEST, "Invalid action for report target");
    }
  }

  public ReportSeverity defaultSeverity(ReportReasonCode reason) {
    return switch (reason) {
      case SPAM -> ReportSeverity.LOW;
      case DANGEROUS_HEALTH_INFORMATION, MISLEADING_NUTRITION_INFORMATION, SCAM_OR_FRAUD ->
          ReportSeverity.HIGH;
      default -> ReportSeverity.MEDIUM;
    };
  }

  public Set<ReportReasonCode> reasonsFor(ReportType type) {
    return switch (type) {
      case PROFILE ->
          Set.of(
              ReportReasonCode.SPAM,
              ReportReasonCode.HARASSMENT,
              ReportReasonCode.IMPERSONATION,
              ReportReasonCode.FALSE_INFORMATION,
              ReportReasonCode.INAPPROPRIATE_PROFILE,
              ReportReasonCode.SCAM_OR_FRAUD,
              ReportReasonCode.OTHER);
      case POST ->
          Set.of(
              ReportReasonCode.SPAM,
              ReportReasonCode.HARASSMENT,
              ReportReasonCode.INAPPROPRIATE_CONTENT,
              ReportReasonCode.FALSE_INFORMATION,
              ReportReasonCode.DANGEROUS_HEALTH_INFORMATION,
              ReportReasonCode.MISLEADING_NUTRITION_INFORMATION,
              ReportReasonCode.STOLEN_CONTENT,
              ReportReasonCode.COPYRIGHT,
              ReportReasonCode.OTHER);
      case COMMENT ->
          Set.of(
              ReportReasonCode.SPAM,
              ReportReasonCode.HARASSMENT,
              ReportReasonCode.HATE_OR_ABUSIVE_CONTENT,
              ReportReasonCode.INAPPROPRIATE_CONTENT,
              ReportReasonCode.FALSE_INFORMATION,
              ReportReasonCode.OTHER);
    };
  }

  public Set<ModerationActionType> actionsFor(ReportType type) {
    return switch (type) {
      case PROFILE ->
          Set.of(
              ModerationActionType.WARNING,
              ModerationActionType.ACCOUNT_RESTRICTED,
              ModerationActionType.POST_RESTRICTED,
              ModerationActionType.COMMENT_RESTRICTED,
              ModerationActionType.SUSPENDED,
              ModerationActionType.BANNED);
      case POST ->
          Set.of(
              ModerationActionType.WARNING,
              ModerationActionType.CONTENT_HIDDEN,
              ModerationActionType.CONTENT_REMOVED,
              ModerationActionType.CONTENT_RESTORED,
              ModerationActionType.POST_RESTRICTED,
              ModerationActionType.COMMENT_RESTRICTED,
              ModerationActionType.SUSPENDED,
              ModerationActionType.BANNED);
      case COMMENT ->
          Set.of(
              ModerationActionType.WARNING,
              ModerationActionType.CONTENT_HIDDEN,
              ModerationActionType.CONTENT_REMOVED,
              ModerationActionType.CONTENT_RESTORED,
              ModerationActionType.POST_RESTRICTED,
              ModerationActionType.COMMENT_RESTRICTED,
              ModerationActionType.SUSPENDED,
              ModerationActionType.BANNED);
    };
  }
}
