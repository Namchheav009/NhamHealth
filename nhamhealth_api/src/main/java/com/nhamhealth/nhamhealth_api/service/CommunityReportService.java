package com.nhamhealth.nhamhealth_api.service;

import static org.springframework.http.HttpStatus.NOT_FOUND;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.nhamhealth.nhamhealth_api.dto.response.CommunityReportReasonResponse;
import com.nhamhealth.nhamhealth_api.entity.Post;
import com.nhamhealth.nhamhealth_api.entity.PostComment;
import com.nhamhealth.nhamhealth_api.entity.PostReport;
import com.nhamhealth.nhamhealth_api.entity.ReportReason;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.entity.Notification;
import com.nhamhealth.nhamhealth_api.repository.NotificationRepository;
import com.nhamhealth.nhamhealth_api.repository.PostCommentRepository;
import com.nhamhealth.nhamhealth_api.repository.PostReportRepository;
import com.nhamhealth.nhamhealth_api.repository.PostRepository;
import com.nhamhealth.nhamhealth_api.repository.ReportReasonRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;

@Service
public class CommunityReportService {
    private final PostRepository posts;
    private final PostCommentRepository comments;
    private final PostReportRepository reports;
    private final ReportReasonRepository reasons;
    private final UserRepository users;
    private final NotificationRepository notifications;
    private final PushNotificationService pushNotifications;

    public CommunityReportService(PostRepository posts, PostCommentRepository comments,
            PostReportRepository reports, ReportReasonRepository reasons, UserRepository users,
            NotificationRepository notifications, PushNotificationService pushNotifications) {
        this.posts = posts;
        this.comments = comments;
        this.reports = reports;
        this.reasons = reasons;
        this.users = users;
        this.notifications = notifications;
        this.pushNotifications = pushNotifications;
    }

    @Transactional(readOnly = true)
    public List<CommunityReportReasonResponse> reasons() {
        return reasons.findAllByIsActiveTrueOrderByReportReasonIdAsc().stream()
                .map(reason -> new CommunityReportReasonResponse(
                        reason.getReportReasonId(), reason.getReasonName()))
                .toList();
    }

    @Transactional
    public void reportPost(Integer reporterId, Integer postId, Integer reasonId) {
        Post post = posts.findById(postId)
                .filter(item -> "ACTIVE".equalsIgnoreCase(item.getStatus()))
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Post not found"));
        if (post.getUser().getUserId().equals(reporterId)) {
            throw new IllegalArgumentException("You cannot report your own post.");
        }
        ReportReason reason = reasons.findById(reasonId)
                .filter(item -> Boolean.TRUE.equals(item.getIsActive()))
                .orElseThrow(() -> new IllegalArgumentException("Select a valid report reason."));
        User reporter = users.findById(reporterId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "User not found"));

        PostReport report = new PostReport();
        report.setPost(post);
        report.setReportedByUser(reporter);
        report.setReportReason(reason);
        report.setStatus("pending");
        report.setTargetType("POST");
        report.setCreatedAt(LocalDateTime.now());
        reports.save(report);
    }

    @Transactional
    public void reportComment(Integer reporterId, Integer postId, Integer commentId, Integer reasonId) {
        PostComment comment = comments.findById(commentId)
                .filter(item -> item.getPost().getPostId().equals(postId))
                .filter(item -> "ACTIVE".equalsIgnoreCase(item.getStatus()))
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Comment not found"));
        if (comment.getUser().getUserId().equals(reporterId)) {
            throw new IllegalArgumentException("You cannot report your own comment.");
        }

        PostReport report = new PostReport();
        report.setPost(comment.getPost());
        report.setComment(comment);
        report.setTargetType("COMMENT");
        report.setReportedByUser(requiredUser(reporterId));
        report.setReportReason(requiredReason(reasonId));
        report.setStatus("pending");
        report.setCreatedAt(LocalDateTime.now());
        reports.save(report);
    }

    /** Applies an intentional moderation decision and notifies only affected users. */
    @Transactional
    public PostReport review(Integer reportId, String status, String action, String adminNote, User reviewer) {
        // The admin controller returns report, author, reason, and reviewer data
        // after this transaction finishes. Load the moderation queue graph here
        // so a valid moderation decision cannot fail while serializing its response.
        PostReport report = reports.findByReportId(reportId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Report not found"));
        String cleanStatus = normalize(status);
        String cleanAction = normalize(action);
        if (!List.of("PENDING", "UNDER_REVIEW", "RESOLVED", "DISMISSED").contains(cleanStatus)) {
            throw new IllegalArgumentException("Select a valid report status.");
        }
        if (!List.of("NONE", "KEEP", "WARN", "REMOVE", "SUSPEND", "BAN").contains(cleanAction)) {
            throw new IllegalArgumentException("Select a valid moderation action.");
        }

        report.setAdminNote(adminNote == null || adminNote.isBlank() ? null : adminNote.trim());
        if ("PENDING".equals(cleanStatus)) {
            report.setStatus("pending");
            report.setModerationAction(null);
            report.setReviewedByUser(null);
            report.setReviewedAt(null);
            return reports.saveAndFlush(report);
        }

        report.setReviewedByUser(reviewer);
        report.setReviewedAt(LocalDateTime.now());
        if ("UNDER_REVIEW".equals(cleanStatus)) {
            report.setStatus("under_review");
            report.setModerationAction(null);
            return reports.saveAndFlush(report);
        }

        if ("DISMISSED".equals(cleanStatus)) {
            if (!"NONE".equals(cleanAction) && !"KEEP".equals(cleanAction)) {
                throw new IllegalArgumentException("A dismissed report can only keep the content.");
            }
            report.setStatus("dismissed");
            report.setModerationAction("keep");
            notifyReporter(report, "Nham Health",
                    "Report reviewed — we reviewed the reported content and did not find a Community Guidelines violation.");
            return reports.saveAndFlush(report);
        }

        if ("NONE".equals(cleanAction) || "KEEP".equals(cleanAction)) {
            throw new IllegalArgumentException("Choose an action before resolving a report.");
        }
        report.setStatus("resolved");
        report.setModerationAction(cleanAction.toLowerCase());
        applyAction(report, cleanAction);
        notifyReporter(report, "Nham Health",
                "Report reviewed — thank you for helping keep the community safe. We reviewed the content and took appropriate action.");
        notifyReportedUser(report, cleanAction);
        return reports.saveAndFlush(report);
    }

    private void applyAction(PostReport report, String action) {
        if ("REMOVE".equals(action) || "SUSPEND".equals(action) || "BAN".equals(action)) {
            if (isCommentReport(report)) {
                report.getComment().setStatus("DELETED");
                report.getComment().setUpdatedAt(LocalDateTime.now());
                comments.save(report.getComment());
            } else {
                report.getPost().setStatus("DELETED");
                report.getPost().setUpdatedAt(LocalDateTime.now());
                posts.save(report.getPost());
            }
        }
        if ("SUSPEND".equals(action)) targetUser(report).setStatus("SUSPENDED");
        if ("BAN".equals(action)) targetUser(report).setStatus("BANNED");
        if ("SUSPEND".equals(action) || "BAN".equals(action)) users.save(targetUser(report));
    }

    private void notifyReporter(PostReport report, String title, String message) {
        notify(report.getReportedByUser(), report.getReviewedByUser(), title, message, report);
    }

    private void notifyReportedUser(PostReport report, String action) {
        String target = isCommentReport(report) ? "comment" : "post";
        String message = switch (action) {
            case "WARN" -> "Your " + target + " received a Community Guidelines warning.";
            case "REMOVE" -> "Your " + target + " was removed for violating Community Guidelines.";
            case "SUSPEND" -> "Your " + target + " was removed and your account was suspended.";
            case "BAN" -> "Your " + target + " was removed and your account was banned.";
            default -> "Your " + target + " was reviewed.";
        };
        notify(targetUser(report), report.getReviewedByUser(), "Nham Health",
                "Community moderation update — " + message, report);
    }

    private void notify(User recipient, User actor, String title, String message, PostReport report) {
        Notification notification = new Notification();
        notification.setUser(recipient);
        notification.setActorUser(actor);
        notification.setNotificationType("MODERATION");
        notification.setReferenceType(isCommentReport(report) ? "COMMENT" : "POST");
        notification.setReferenceId(isCommentReport(report)
                ? report.getComment().getCommentId() : report.getPost().getPostId());
        notification.setTitle(title);
        notification.setMessage(message);
        notification.setIsRead(false);
        notification.setCreatedAt(LocalDateTime.now());
        pushNotifications.send(notifications.saveAndFlush(notification));
    }

    private boolean isCommentReport(PostReport report) {
        return "COMMENT".equalsIgnoreCase(report.getTargetType()) && report.getComment() != null;
    }

    private User targetUser(PostReport report) {
        return isCommentReport(report) ? report.getComment().getUser() : report.getPost().getUser();
    }

    private ReportReason requiredReason(Integer reasonId) {
        return reasons.findById(reasonId).filter(item -> Boolean.TRUE.equals(item.getIsActive()))
                .orElseThrow(() -> new IllegalArgumentException("Select a valid report reason."));
    }

    private User requiredUser(Integer userId) {
        return users.findById(userId).orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "User not found"));
    }

    private String normalize(String value) {
        return value == null ? "NONE" : value.trim().toUpperCase();
    }
}
