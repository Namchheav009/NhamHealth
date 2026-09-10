package com.nhamhealth.nhamhealth_api.service.community;

import static org.springframework.http.HttpStatus.*;

import com.nhamhealth.nhamhealth_api.dto.request.*;
import com.nhamhealth.nhamhealth_api.dto.response.*;
import com.nhamhealth.nhamhealth_api.entity.*;
import com.nhamhealth.nhamhealth_api.repository.community.*;
import com.nhamhealth.nhamhealth_api.repository.notification.NotificationRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserProfileRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;
import com.nhamhealth.nhamhealth_api.service.notification.PushNotificationService;
import java.time.LocalDateTime;
import java.util.*;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class ReportModerationService {
  private static final Set<ReportStatus> ACTIVE =
      Set.of(ReportStatus.PENDING, ReportStatus.UNDER_REVIEW);
  private final ReportRepository reports;
  private final ModerationActionRepository actions;
  private final ModerationAppealRepository appeals;
  private final UserRepository users;
  private final PostRepository posts;
  private final PostCommentRepository comments;
  private final NotificationRepository notifications;
  private final PushNotificationService push;
  private final ReportModerationPolicy policy;
  private final UserProfileRepository profiles;

  public ReportModerationService(
      ReportRepository reports,
      ModerationActionRepository actions,
      ModerationAppealRepository appeals,
      UserRepository users,
      PostRepository posts,
      PostCommentRepository comments,
      NotificationRepository notifications,
      PushNotificationService push,
      ReportModerationPolicy policy,
      UserProfileRepository profiles) {
    this.reports = reports;
    this.actions = actions;
    this.appeals = appeals;
    this.users = users;
    this.posts = posts;
    this.comments = comments;
    this.notifications = notifications;
    this.push = push;
    this.policy = policy;
    this.profiles = profiles;
  }

  @Transactional
  public ReportResponse create(Integer reporterId, CreateReportRequest request) {
    User reporter = user(reporterId);
    Target target = validateTarget(request.reportType(), request.targetId());
    User owner = target.owner();
    if (reporterId.equals(owner.getUserId()))
      throw new ResponseStatusException(BAD_REQUEST, "You cannot report yourself");
    policy.requireAllowedReason(request.reportType(), request.reason());
    String description = clean(request.description());
    if (request.reason() == ReportReasonCode.OTHER
        && (description == null || description.isBlank()))
      throw new ResponseStatusException(BAD_REQUEST, "Please provide details for Something else");
    if (reports.existsByReporterUserIdAndReportTypeAndTargetIdAndStatusIn(
        reporterId, request.reportType(), request.targetId(), ACTIVE))
      throw new ResponseStatusException(
          CONFLICT, "You have already reported this item. Our team is reviewing your report.");
    Report r = new Report();
    r.setReporter(reporter);
    r.setReportedUser(owner);
    r.setReportType(request.reportType());
    r.setTargetId(request.targetId());
    r.setReason(request.reason());
    r.setDescription(description);
    r.setContentSnapshot(target.snapshot());
    r.setSeverity(policy.defaultSeverity(request.reason()));
    r = reports.saveAndFlush(r);
    notify(
        reporter,
        null,
        "REPORT",
        "Report submitted",
        "Thanks for letting us know. Our team will review your report.",
        request.reportType().name(),
        request.targetId());
    return safe(r);
  }

  @Transactional(readOnly = true)
  public Page<ReportResponse> mine(Integer userId, Pageable pageable) {
    return reports.findByReporterUserIdOrderByCreatedAtDesc(userId, pageable).map(this::safe);
  }

  @Transactional(readOnly = true)
  public Page<AdminReportResponse> list(
      ReportType type,
      ReportStatus status,
      ReportReasonCode reason,
      ReportSeverity severity,
      Integer reportedUserId,
      String search,
      LocalDateTime from,
      LocalDateTime to,
      Pageable pageable) {
    return reports
        .findAll(
            (root, q, cb) -> {
              var p = new ArrayList<jakarta.persistence.criteria.Predicate>();
              if (type != null) p.add(cb.equal(root.get("reportType"), type));
              if (status != null) p.add(cb.equal(root.get("status"), status));
              if (reason != null) p.add(cb.equal(root.get("reason"), reason));
              if (severity != null) p.add(cb.equal(root.get("severity"), severity));
              if (reportedUserId != null)
                p.add(cb.equal(root.get("reportedUser").get("userId"), reportedUserId));
              if (from != null) p.add(cb.greaterThanOrEqualTo(root.get("createdAt"), from));
              if (to != null) p.add(cb.lessThanOrEqualTo(root.get("createdAt"), to));
              if (search != null && !search.isBlank()) {
                String s = "%" + search.trim().toLowerCase() + "%";
                var matches = new ArrayList<jakarta.persistence.criteria.Predicate>();
                matches.add(cb.like(cb.lower(root.get("description")), s));
                matches.add(cb.like(cb.lower(root.get("reporter").get("email")), s));
                matches.add(cb.like(cb.lower(root.get("reportedUser").get("email")), s));
                try {
                  Integer numericSearch = Integer.valueOf(search.trim().replaceFirst("^#", ""));
                  matches.add(cb.equal(root.get("reportId"), numericSearch));
                  matches.add(cb.equal(root.get("targetId"), numericSearch));
                } catch (NumberFormatException ignored) {
                  // Text searches are matched against human-readable fields above.
                }
                p.add(cb.or(matches.toArray(jakarta.persistence.criteria.Predicate[]::new)));
              }
              return cb.and(p.toArray(jakarta.persistence.criteria.Predicate[]::new));
            },
            pageable)
        .map(this::admin);
  }

  @Transactional(readOnly = true)
  public AdminReportResponse detail(Integer id) {
    return admin(report(id));
  }

  @Transactional
  public AdminReportResponse startReview(Integer id, Integer adminId, ReviewReportRequest request) {
    Report r = report(id);
    if (r.getStatus() != ReportStatus.PENDING)
      throw new ResponseStatusException(CONFLICT, "Only pending reports can be started");
    r.setStatus(ReportStatus.UNDER_REVIEW);
    r.setReviewedBy(user(adminId));
    r.setReviewedAt(LocalDateTime.now());
    if (request != null) {
      r.setAdminNote(clean(request.adminNote()));
      if (request.severity() != null) r.setSeverity(request.severity());
    }
    return admin(reports.saveAndFlush(r));
  }

  @Transactional
  public AdminReportResponse dismiss(Integer id, Integer adminId, ReviewReportRequest request) {
    Report r = report(id);
    if (r.getStatus() != ReportStatus.UNDER_REVIEW)
      throw new ResponseStatusException(CONFLICT, "Start review before making a decision");
    r.setStatus(ReportStatus.DISMISSED);
    r.setReviewedBy(user(adminId));
    r.setReviewedAt(LocalDateTime.now());
    if (request != null) {
      r.setAdminNote(clean(request.adminNote()));
      if (request.severity() != null) r.setSeverity(request.severity());
    }
    r = reports.saveAndFlush(r);
    notify(
        r.getReporter(),
        null,
        "MODERATION",
        "Report reviewed",
        "Your report has been reviewed. Thank you for helping keep NhamHealth safe.",
        r.getReportType().name(),
        r.getTargetId());
    return admin(r);
  }

  @Transactional
  public ModerationActionResponse act(
      Integer id, Integer adminId, ModerationActionRequest request) {
    Report r = report(id);
    if (r.getStatus() != ReportStatus.UNDER_REVIEW)
      throw new ResponseStatusException(CONFLICT, "Start review before making a decision");
    policy.requireAllowedAction(r.getReportType(), request.actionType());
    LocalDateTime start = request.startsAt() == null ? LocalDateTime.now() : request.startsAt();
    if (request.actionType() == ModerationActionType.SUSPENDED
        && (request.expiresAt() == null || !request.expiresAt().isAfter(start)))
      throw new ResponseStatusException(
          BAD_REQUEST, "Suspension expiration must be after its start");
    ModerationAction a = new ModerationAction();
    a.setReport(r);
    a.setTargetUser(r.getReportedUser());
    a.setAdminUser(user(adminId));
    a.setActionType(request.actionType());
    a.setReason(r.getReason());
    a.setAdminNote(clean(request.adminNote()));
    a.setStartsAt(start);
    a.setExpiresAt(request.expiresAt());
    applyContentState(r, a.getActionType());
    applyAccountState(a);
    a = actions.saveAndFlush(a);
    r.setStatus(ReportStatus.RESOLVED);
    r.setReviewedBy(a.getAdminUser());
    r.setReviewedAt(LocalDateTime.now());
    r.setAdminNote(a.getAdminNote());
    reports.saveAndFlush(r);
    notify(
        r.getReporter(),
        null,
        "MODERATION",
        "Report reviewed",
        "Your report has been reviewed. Thank you for helping keep NhamHealth safe.",
        r.getReportType().name(),
        r.getTargetId());
    notify(
        r.getReportedUser(),
        null,
        "MODERATION",
        title(a.getActionType()),
        message(a),
        r.getReportType().name(),
        r.getTargetId());
    return action(a);
  }

  @Transactional
  public AppealResponse appeal(Integer userId, AppealRequest request) {
    ModerationAction a =
        actions
            .findById(request.moderationActionId())
            .orElseThrow(
                () -> new ResponseStatusException(NOT_FOUND, "Moderation action not found"));
    if (!a.getTargetUser().getUserId().equals(userId))
      throw new ResponseStatusException(
          FORBIDDEN, "You can only appeal your own moderation action");
    if (!Set.of(
            ModerationActionType.ACCOUNT_RESTRICTED,
            ModerationActionType.SUSPENDED,
            ModerationActionType.BANNED)
        .contains(a.getActionType()))
      throw new ResponseStatusException(BAD_REQUEST, "This action cannot be appealed");
    if (appeals.existsByModerationActionActionIdAndUserUserId(a.getActionId(), userId))
      throw new ResponseStatusException(CONFLICT, "An appeal already exists for this action");
    ModerationAppeal x = new ModerationAppeal();
    x.setModerationAction(a);
    x.setUser(user(userId));
    x.setReason(request.reason().trim());
    return appeal(appeals.saveAndFlush(x));
  }

  @Transactional(readOnly = true)
  public Page<AppealResponse> appeals(AppealStatus status, Pageable pageable) {
    return appeals
        .findByStatusOrderByCreatedAtAsc(status == null ? AppealStatus.PENDING : status, pageable)
        .map(this::appeal);
  }

  @Transactional
  public AppealResponse reviewAppeal(Integer id, Integer adminId, ReviewAppealRequest request) {
    if (request.status() == AppealStatus.PENDING)
      throw new ResponseStatusException(BAD_REQUEST, "Choose APPROVED or REJECTED");
    ModerationAppeal x =
        appeals
            .findById(id)
            .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Appeal not found"));
    if (x.getStatus() != AppealStatus.PENDING)
      throw new ResponseStatusException(CONFLICT, "Appeal has already been reviewed");
    x.setStatus(request.status());
    x.setAdminNote(clean(request.adminNote()));
    x.setReviewedAt(LocalDateTime.now());
    x.setReviewedBy(user(adminId));
    if (request.status() == AppealStatus.APPROVED) {
      ModerationAction a = x.getModerationAction();
      a.setReversedAt(LocalDateTime.now());
      a.setReversedBy(x.getReviewedBy());
      actions.save(a);
      if (Set.of(
              ModerationActionType.ACCOUNT_RESTRICTED,
              ModerationActionType.SUSPENDED,
              ModerationActionType.BANNED)
          .contains(a.getActionType())) {
        a.getTargetUser().setStatus("ACTIVE");
        a.getTargetUser().invalidateSessions();
        users.save(a.getTargetUser());
      }
    }
    x = appeals.saveAndFlush(x);
    notify(
        x.getUser(),
        null,
        "MODERATION",
        "Appeal reviewed",
        request.status() == AppealStatus.APPROVED
            ? "Your moderation appeal was approved and the action was reversed."
            : "Your moderation appeal was reviewed and the action remains in place.",
        "MODERATION_ACTION",
        x.getModerationAction().getActionId());
    return appeal(x);
  }

  @Transactional(readOnly = true)
  public Page<ModerationActionResponse> history(Pageable pageable) {
    return actions.findAllByOrderByCreatedAtDesc(pageable).map(this::action);
  }

  private Target validateTarget(ReportType type, Integer id) {
    return switch (type) {
      case PROFILE -> new Target(user(id), null);
      case POST ->
          posts
              .findById(id)
              .map(post -> new Target(post.getUser(), snapshot(post)))
              .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Post not found"));
      case COMMENT ->
          comments
              .findById(id)
              .map(comment -> new Target(comment.getUser(), truncate(comment.getCommentText(), 1000)))
              .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Comment not found"));
    };
  }

  private String snapshot(Post post) {
    String value = post.getCaption();
    if ((value == null || value.isBlank()) && post.getRecipe() != null) {
      value = String.join(" — ",
          Optional.ofNullable(post.getRecipe().getRecipeName()).orElse(""),
          Optional.ofNullable(post.getRecipe().getDescription()).orElse(""));
    }
    return truncate(value, 1000);
  }

  private String truncate(String value, int max) {
    if (value == null || value.isBlank()) return null;
    String cleaned = value.trim();
    return cleaned.length() <= max ? cleaned : cleaned.substring(0, max);
  }

  private record Target(User owner, String snapshot) {}

  private void applyAccountState(ModerationAction a) {
    if (a.getActionType() == ModerationActionType.SUSPENDED)
      a.getTargetUser().setStatus("SUSPENDED");
    else if (a.getActionType() == ModerationActionType.BANNED)
      a.getTargetUser().setStatus("BANNED");
    // Restrictions are recorded as scoped moderation actions. They must not
    // disable authentication the way suspension and banning do.
    else return;
    a.getTargetUser().invalidateSessions();
    users.save(a.getTargetUser());
  }

  private void applyContentState(Report r, ModerationActionType type) {
    if (type != ModerationActionType.CONTENT_HIDDEN && type != ModerationActionType.CONTENT_REMOVED)
      return;
    String state = type == ModerationActionType.CONTENT_HIDDEN ? "HIDDEN" : "REMOVED";
    if (r.getReportType() == ReportType.COMMENT) {
      PostComment c =
          comments
              .findById(r.getTargetId())
              .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Comment not found"));
      c.setStatus(state);
      c.setUpdatedAt(LocalDateTime.now());
      comments.save(c);
    } else if (r.getReportType() == ReportType.POST) {
      Post p =
          posts
              .findById(r.getTargetId())
              .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Post not found"));
      if (p.getRecipe() != null) {
        p.getRecipe()
            .setStatus(type == ModerationActionType.CONTENT_HIDDEN ? "HIDDEN" : "REMOVED");
        p.getRecipe().setUpdatedAt(LocalDateTime.now());
      }
    }
  }

  private User user(Integer id) {
    return users
        .findById(id)
        .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "User not found"));
  }

  private Report report(Integer id) {
    return reports
        .findById(id)
        .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Report not found"));
  }

  private String clean(String s) {
    return s == null || s.isBlank() ? null : s.trim();
  }

  private String name(User u) {
    return profiles
        .findByUser_UserId(u.getUserId())
        .map(UserProfile::getFullName)
        .filter(value -> value != null && !value.isBlank())
        .orElseGet(u::getName);
  }

  private String targetSummary(Report report) {
    return switch (report.getReportType()) {
      case PROFILE -> name(report.getReportedUser());
      case POST ->
          posts
              .findById(report.getTargetId())
              .map(
                  post ->
                      post.getRecipe() != null && post.getRecipe().getRecipeName() != null
                          ? post.getRecipe().getRecipeName()
                          : post.getCaption())
              .filter(value -> value != null && !value.isBlank())
              .orElse("Post #" + report.getTargetId());
      case COMMENT ->
          comments
              .findById(report.getTargetId())
              .map(PostComment::getCommentText)
              .filter(value -> value != null && !value.isBlank())
              .map(value -> value.length() > 80 ? value.substring(0, 80) + "…" : value)
              .orElse("Comment #" + report.getTargetId());
    };
  }

  private ReportResponse safe(Report r) {
    return new ReportResponse(
        r.getReportId(),
        r.getReportType(),
        r.getTargetId(),
        r.getReason(),
        r.getDescription(),
        r.getStatus(),
        r.getSeverity(),
        r.getCreatedAt(),
        r.getUpdatedAt());
  }

  private AdminReportResponse admin(Report r) {
    return new AdminReportResponse(
        r.getReportId(),
        r.getReportType(),
        r.getTargetId(),
        r.getReason(),
        r.getDescription(),
        r.getStatus(),
        r.getSeverity(),
        r.getCreatedAt(),
        r.getReporter().getUserId(),
        name(r.getReporter()),
        r.getReportedUser().getUserId(),
        name(r.getReportedUser()),
        targetSummary(r),
        r.getContentSnapshot(),
        Math.max(0, reports.countByReportedUserUserId(r.getReportedUser().getUserId()) - 1),
        actions.findByTargetUserUserIdOrderByCreatedAtDesc(r.getReportedUser().getUserId()).stream()
            .map(this::action)
            .toList(),
        r.getAdminNote());
  }

  private ModerationActionResponse action(ModerationAction a) {
    return new ModerationActionResponse(
        a.getActionId(),
        a.getReport() == null ? null : a.getReport().getReportId(),
        a.getTargetUser().getUserId(),
        name(a.getAdminUser()),
        a.getActionType(),
        a.getReason(),
        a.getAdminNote(),
        a.getStartsAt(),
        a.getExpiresAt(),
        a.getCreatedAt(),
        a.getReversedAt() != null);
  }

  private AppealResponse appeal(ModerationAppeal a) {
    return new AppealResponse(
        a.getAppealId(),
        a.getModerationAction().getActionId(),
        a.getUser().getUserId(),
        a.getReason(),
        a.getStatus(),
        a.getAdminNote(),
        a.getCreatedAt(),
        a.getReviewedAt());
  }

  private String title(ModerationActionType t) {
    return t == ModerationActionType.SUSPENDED
        ? "Account temporarily suspended"
        : t == ModerationActionType.WARNING
            ? "Community Guidelines Warning"
            : "Moderation action taken";
  }

  private String message(ModerationAction a) {
    return "Some activity on your account violated NhamHealth Community Guidelines. Reason: "
        + a.getReason().name().replace('_', ' ')
        + (a.getExpiresAt() == null ? "" : "; until " + a.getExpiresAt());
  }

  private void notify(
      User recipient,
      User actor,
      String type,
      String title,
      String message,
      String refType,
      Integer refId) {
    Notification n = new Notification();
    n.setUser(recipient);
    n.setActorUser(actor);
    n.setNotificationType(type);
    n.setTitle(title);
    n.setMessage(message);
    n.setReferenceType(refType);
    n.setReferenceId(refId);
    n.setIsRead(false);
    n.setCreatedAt(LocalDateTime.now());
    push.send(notifications.saveAndFlush(n));
  }
}
