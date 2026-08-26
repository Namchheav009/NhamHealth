package com.nhamhealth.nhamhealth_api.controller.admin;

import java.util.List;
import java.util.Map;
import java.util.Objects;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.server.ResponseStatusException;

import com.nhamhealth.nhamhealth_api.entity.Post;
import com.nhamhealth.nhamhealth_api.entity.PostComment;
import com.nhamhealth.nhamhealth_api.entity.PostMedia;
import com.nhamhealth.nhamhealth_api.entity.PostReport;
import com.nhamhealth.nhamhealth_api.entity.ReportReason;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.PostReportRepository;
import com.nhamhealth.nhamhealth_api.repository.PostMediaRepository;
import com.nhamhealth.nhamhealth_api.repository.PostRepository;
import com.nhamhealth.nhamhealth_api.repository.ReportReasonRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;
import com.nhamhealth.nhamhealth_api.service.CommunityReportService;

@Controller
public class ReportAdminController {
    private final PostReportRepository reportRepository;
    private final PostRepository postRepository;
    private final PostMediaRepository mediaRepository;
    private final UserRepository userRepository;
    private final ReportReasonRepository reasonRepository;
    private final CommunityReportService reportService;

    public ReportAdminController(PostReportRepository reportRepository, PostRepository postRepository,
            PostMediaRepository mediaRepository,
            UserRepository userRepository, ReportReasonRepository reasonRepository,
            CommunityReportService reportService) {
        this.reportRepository = reportRepository;
        this.postRepository = postRepository;
        this.mediaRepository = mediaRepository;
        this.userRepository = userRepository;
        this.reasonRepository = reasonRepository;
        this.reportService = reportService;
    }

    @GetMapping("/admin/reports/{reportId}/target")
    @ResponseBody
    public ResponseEntity<?> reportedTarget(@PathVariable Integer reportId) {
        return reportRepository.findByReportId(reportId)
                .map(report -> ResponseEntity.ok(toTargetResponse(report)))
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @GetMapping("/admin/reports")
    public String reportsPage(Authentication authentication, Model model) {
        List<PostReport> reports = reportRepository.findAllByOrderByCreatedAtDesc();
        long uniqueReporters = reports.stream().map(PostReport::getReportedByUser).filter(Objects::nonNull)
                .map(User::getUserId).distinct().count();
        model.addAttribute("pageTitle", "Reports");
        model.addAttribute("activePage", "reports");
        model.addAttribute("adminName", authentication != null ? authentication.getName() : "admin");
        model.addAttribute("reports", reports);
        model.addAttribute("posts", postRepository.findAllByOrderByUpdatedAtDescCreatedAtDesc());
        model.addAttribute("users", userRepository.findAll());
        model.addAttribute("reasons", reasonRepository.findAllByIsActiveTrueOrderByReasonNameAsc());
        model.addAttribute("totalReports", reports.size());
        model.addAttribute("uniqueReporters", uniqueReporters);
        model.addAttribute("pendingReports", reportRepository.countByStatusIgnoreCase("pending"));
        return "admin/report";
    }

    /** Manual creation remains available for moderation testing and historical imports. */
    @PostMapping("/admin/reports")
    @ResponseBody
    public ResponseEntity<?> createReport(@RequestParam Integer postId, @RequestParam Integer reporterId,
            @RequestParam Integer reasonId) {
        Post post = postRepository.findById(postId).orElse(null);
        User reporter = userRepository.findById(reporterId).orElse(null);
        ReportReason reason = reasonRepository.findById(reasonId)
                .filter(item -> Boolean.TRUE.equals(item.getIsActive())).orElse(null);
        if (post == null || reporter == null || reason == null) {
            return ResponseEntity.badRequest().body(Map.of("message", "Select a valid post, reporter, and active reason."));
        }
        PostReport report = new PostReport();
        report.setPost(post);
        report.setTargetType("POST");
        report.setReportedByUser(reporter);
        report.setReportReason(reason);
        report.setStatus("pending");
        report.setCreatedAt(java.time.LocalDateTime.now());
        return ResponseEntity.ok(toResponse(reportRepository.saveAndFlush(report)));
    }

    @PatchMapping("/admin/reports/{reportId}/status")
    @ResponseBody
    public ResponseEntity<?> reviewReport(@PathVariable Integer reportId, @RequestParam String status,
            @RequestParam(defaultValue = "none") String action,
            @RequestParam(required = false) String adminNote, Authentication authentication) {
        User reviewer = authentication == null ? null
                : userRepository.findByEmailIgnoreCase(authentication.getName()).orElse(null);
        if (reviewer == null) return ResponseEntity.status(401).body(Map.of("message", "Admin account not found."));
        try {
            return ResponseEntity.ok(toResponse(reportService.review(reportId, status, action, adminNote, reviewer)));
        } catch (ResponseStatusException exception) {
            return ResponseEntity.status(exception.getStatusCode()).body(Map.of("message", exception.getReason()));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.badRequest().body(Map.of("message", exception.getMessage()));
        }
    }

    private Map<String, Object> toResponse(PostReport report) {
        User reporter = report.getReportedByUser();
        Post post = report.getPost();
        PostComment comment = report.getComment();
        boolean commentReport = "COMMENT".equalsIgnoreCase(report.getTargetType()) && comment != null;
        String content = commentReport ? comment.getCommentText() : displayPostContent(post);
        String summary = content == null ? "" : content.length() > 80 ? content.substring(0, 80) + "..." : content;
        String reviewer = report.getReviewedByUser() == null || report.getReviewedByUser().getName() == null
                ? "" : report.getReviewedByUser().getName();
        return Map.ofEntries(
                Map.entry("id", report.getReportId()), Map.entry("reporterId", reporter.getUserId()),
                Map.entry("reporterName", reporter.getName() == null ? "Unknown user" : reporter.getName()),
                Map.entry("reporterEmail", reporter.getEmail() == null ? "" : reporter.getEmail()),
                Map.entry("postId", post.getPostId()), Map.entry("targetSummary", summary),
                Map.entry("targetType", commentReport ? "comment" : "post"),
                Map.entry("reason", report.getReportReason().getReasonName()), Map.entry("status", report.getStatus()),
                Map.entry("action", report.getModerationAction() == null ? "" : report.getModerationAction()),
                Map.entry("reviewer", reviewer),
                Map.entry("createdAt", report.getCreatedAt().toString()));
    }

    private Map<String, Object> toTargetResponse(PostReport report) {
        Post post = report.getPost();
        PostComment comment = report.getComment();
        boolean commentReport = "COMMENT".equalsIgnoreCase(report.getTargetType()) && comment != null;
        User author = commentReport ? comment.getUser() : post.getUser();
        String content = commentReport ? comment.getCommentText() : displayPostContent(post);
        List<String> imageUrls = imageUrlsFor(post);
        return Map.ofEntries(
                Map.entry("reportId", report.getReportId()),
                Map.entry("targetType", commentReport ? "Comment" : "Post"),
                Map.entry("targetId", commentReport ? comment.getCommentId() : post.getPostId()),
                Map.entry("content", content == null ? "" : content),
                Map.entry("postId", post.getPostId()),
                Map.entry("postContent", displayPostContent(post)),
                Map.entry("author", author.getName() == null ? "Unknown user" : author.getName()),
                Map.entry("authorEmail", author.getEmail() == null ? "" : author.getEmail()),
                Map.entry("contentStatus", commentReport ? comment.getStatus() : post.getStatus()),
                Map.entry("createdAt", commentReport ? comment.getCreatedAt().toString() : post.getCreatedAt().toString()),
                Map.entry("imageUrls", imageUrls));
    }

    private String displayPostContent(Post post) {
        if (post.getCaption() != null && !post.getCaption().isBlank()) {
            return post.getCaption();
        }
        Post sharedPost = post.getSharedPost();
        if (sharedPost != null && sharedPost.getCaption() != null && !sharedPost.getCaption().isBlank()) {
            return "Shared post: " + sharedPost.getCaption();
        }
        return "This post has no written caption. Review any attached images before taking action.";
    }

    private List<String> imageUrlsFor(Post post) {
        List<String> imageUrls = mediaRepository.findByPostPostIdOrderByDisplayOrder(post.getPostId()).stream()
                .map(PostMedia::getMediaUrl).toList();
        if (!imageUrls.isEmpty() || post.getSharedPost() == null) {
            return imageUrls;
        }
        return mediaRepository.findByPostPostIdOrderByDisplayOrder(post.getSharedPost().getPostId()).stream()
                .map(PostMedia::getMediaUrl).toList();
    }
}
