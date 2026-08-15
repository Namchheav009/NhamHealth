package com.nhamhealth.nhamhealth_api.controller.admin;

import java.time.LocalDateTime;
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

import com.nhamhealth.nhamhealth_api.entity.Post;
import com.nhamhealth.nhamhealth_api.entity.PostReport;
import com.nhamhealth.nhamhealth_api.entity.ReportReason;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.PostReportRepository;
import com.nhamhealth.nhamhealth_api.repository.PostRepository;
import com.nhamhealth.nhamhealth_api.repository.ReportReasonRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;

@Controller
public class ReportAdminController {
    private static final List<String> VALID_STATUSES = List.of("pending", "resolved", "dismissed");

    private final PostReportRepository reportRepository;
    private final PostRepository postRepository;
    private final UserRepository userRepository;
    private final ReportReasonRepository reasonRepository;

    public ReportAdminController(PostReportRepository reportRepository, PostRepository postRepository,
            UserRepository userRepository, ReportReasonRepository reasonRepository) {
        this.reportRepository = reportRepository;
        this.postRepository = postRepository;
        this.userRepository = userRepository;
        this.reasonRepository = reasonRepository;
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

    @PostMapping("/admin/reports")
    @ResponseBody
    public ResponseEntity<?> createReport(@RequestParam Integer postId, @RequestParam Integer reporterId,
            @RequestParam Integer reasonId) {
        Post post = postRepository.findById(postId).orElse(null);
        User reporter = userRepository.findById(reporterId).orElse(null);
        ReportReason reason = reasonRepository.findById(reasonId).filter(r -> Boolean.TRUE.equals(r.getIsActive())).orElse(null);
        if (post == null || reporter == null || reason == null) {
            return ResponseEntity.badRequest().body(Map.of("message", "Select a valid post, reporter, and active reason."));
        }
        PostReport report = new PostReport();
        report.setPost(post);
        report.setReportedByUser(reporter);
        report.setReportReason(reason);
        report.setStatus("pending");
        report.setCreatedAt(LocalDateTime.now());
        return ResponseEntity.ok(toResponse(reportRepository.saveAndFlush(report)));
    }

    @PatchMapping("/admin/reports/{reportId}/status")
    @ResponseBody
    public ResponseEntity<?> updateStatus(@PathVariable Integer reportId, @RequestParam String status,
            Authentication authentication) {
        String cleanStatus = status == null ? "" : status.trim().toLowerCase();
        if (!VALID_STATUSES.contains(cleanStatus)) {
            return ResponseEntity.badRequest().body(Map.of("message", "Select a valid report status."));
        }
        PostReport report = reportRepository.findById(reportId).orElse(null);
        if (report == null) return ResponseEntity.notFound().build();
        report.setStatus(cleanStatus);
        if (cleanStatus.equals("pending")) {
            report.setReviewedByUser(null);
            report.setReviewedAt(null);
        } else {
            if (authentication != null) userRepository.findByEmailIgnoreCase(authentication.getName())
                    .ifPresent(report::setReviewedByUser);
            report.setReviewedAt(LocalDateTime.now());
        }
        return ResponseEntity.ok(toResponse(reportRepository.saveAndFlush(report)));
    }

    private Map<String, Object> toResponse(PostReport report) {
        User reporter = report.getReportedByUser();
        Post post = report.getPost();
        String caption = post.getCaption() == null ? "" : post.getCaption();
        String summary = caption.length() > 80 ? caption.substring(0, 80) + "…" : caption;
        String reviewer = report.getReviewedByUser() == null || report.getReviewedByUser().getName() == null
                ? "" : report.getReviewedByUser().getName();
        return Map.ofEntries(
                Map.entry("id", report.getReportId()), Map.entry("reporterId", reporter.getUserId()),
                Map.entry("reporterName", reporter.getName() == null ? "Unknown user" : reporter.getName()),
                Map.entry("reporterEmail", reporter.getEmail() == null ? "" : reporter.getEmail()),
                Map.entry("postId", post.getPostId()), Map.entry("targetSummary", summary),
                Map.entry("reason", report.getReportReason().getReasonName()), Map.entry("status", report.getStatus()),
                Map.entry("reviewer", reviewer),
                Map.entry("createdAt", report.getCreatedAt().toString()));
    }
}
