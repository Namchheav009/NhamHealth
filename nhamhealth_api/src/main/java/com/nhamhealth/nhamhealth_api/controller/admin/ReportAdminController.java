package com.nhamhealth.nhamhealth_api.controller.admin;

import com.nhamhealth.nhamhealth_api.dto.request.*;
import com.nhamhealth.nhamhealth_api.dto.response.*;
import com.nhamhealth.nhamhealth_api.entity.*;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;
import com.nhamhealth.nhamhealth_api.service.community.ReportModerationService;
import java.time.LocalDateTime;
import org.springframework.data.domain.*;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller
public class ReportAdminController {
  private static final int PAGE_SIZE = 20;
  private final ReportModerationService reports;
  private final UserRepository users;

  public ReportAdminController(ReportModerationService reports, UserRepository users) {
    this.reports = reports;
    this.users = users;
  }

  @GetMapping("/admin/reports")
  public String allReports(Model model) {
    return queue(model, "All Reports", "reports-all", null);
  }

  @GetMapping("/admin/reports/profiles")
  public String profileReports(Model model) {
    return queue(model, "Profile Reports", "reports-profiles", ReportType.PROFILE);
  }

  @GetMapping("/admin/reports/posts")
  public String postReports(Model model) {
    return queue(model, "Post Reports", "reports-posts", ReportType.POST);
  }

  @GetMapping("/admin/reports/comments")
  public String commentReports(Model model) {
    return queue(model, "Comment Reports", "reports-comments", ReportType.COMMENT);
  }

  @GetMapping("/admin/reports/{id:\\d+}")
  public String reportDetail(@PathVariable Integer id, Model model) {
    AdminReportResponse report = reports.detail(id);
    model.addAttribute("pageTitle", "Report #" + id);
    model.addAttribute("activePage", activePage(report.type()));
    model.addAttribute("report", report);
    addReturnDestination(model, report.type());
    model.addAttribute("reviewMode", false);
    return "admin/report-detail";
  }

  @GetMapping("/admin/reports/{id:\\d+}/review")
  public String reportReview(@PathVariable Integer id, Authentication authentication, Model model) {
    AdminReportResponse report = reports.detail(id);
    if (report.status() == ReportStatus.PENDING) {
      report =
          reports.startReview(
              id, admin(authentication).getUserId(), new ReviewReportRequest(null, null));
    }
    model.addAttribute("pageTitle", "Review Report #" + id);
    model.addAttribute("activePage", activePage(report.type()));
    model.addAttribute("report", report);
    addReturnDestination(model, report.type());
    model.addAttribute("reviewMode", true);
    return "admin/report-detail";
  }

  @GetMapping("/admin/reports/appeals")
  public String appeals(Model model) {
    model.addAttribute("pageTitle", "Appeals");
    model.addAttribute("activePage", "reports-appeals");
    return "admin/report-appeals";
  }

  @GetMapping("/admin/reports/moderation-history")
  public String moderationHistory(Model model) {
    model.addAttribute("pageTitle", "Moderation History");
    model.addAttribute("activePage", "reports-history");
    return "admin/moderation-history";
  }

  @GetMapping("/admin/reports/data")
  @ResponseBody
  public Page<AdminReportResponse> reportData(
      @RequestParam(required = false) ReportType type,
      @RequestParam(required = false) ReportStatus status,
      @RequestParam(required = false) ReportReasonCode reason,
      @RequestParam(required = false) ReportSeverity severity,
      @RequestParam(required = false) Integer reportedUserId,
      @RequestParam(required = false) String search,
      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME)
          LocalDateTime from,
      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME)
          LocalDateTime to,
      @RequestParam(defaultValue = "0") int page) {
    return reports.list(
        type,
        status,
        reason,
        severity,
        reportedUserId,
        search,
        from,
        to,
        PageRequest.of(Math.max(0, page), PAGE_SIZE, Sort.by(Sort.Order.desc("createdAt"))));
  }

  @GetMapping("/admin/reports/summary")
  @ResponseBody
  public ReportSummary summary() {
    return new ReportSummary(
        count(null),
        count(ReportStatus.PENDING),
        count(ReportStatus.UNDER_REVIEW),
        count(ReportStatus.RESOLVED),
        count(ReportStatus.NO_VIOLATION) + count(ReportStatus.REJECTED)
            + count(ReportStatus.DISMISSED));
  }

  @PatchMapping("/admin/reports/{id:\\d+}/start-review")
  @ResponseBody
  public AdminReportResponse startReview(
      @PathVariable Integer id,
      Authentication auth,
      @RequestBody(required = false) ReviewReportRequest request) {
    return reports.startReview(id, admin(auth).getUserId(), request);
  }

  @PatchMapping("/admin/reports/{id:\\d+}/dismiss")
  @ResponseBody
  public AdminReportResponse dismiss(
      @PathVariable Integer id,
      Authentication auth,
      @RequestBody(required = false) ReviewReportRequest request) {
    return reports.dismiss(id, admin(auth).getUserId(), request);
  }

  @PostMapping("/admin/reports/{id:\\d+}/actions")
  @ResponseBody
  public ModerationActionResponse action(
      @PathVariable Integer id, Authentication auth, @RequestBody ModerationActionRequest request) {
    return reports.act(id, admin(auth).getUserId(), request);
  }

  @GetMapping("/admin/reports/appeals/data")
  @ResponseBody
  public Page<AppealResponse> appealData(
      @RequestParam(defaultValue = "PENDING") AppealStatus status,
      @RequestParam(defaultValue = "0") int page) {
    return reports.appeals(status, PageRequest.of(Math.max(0, page), PAGE_SIZE));
  }

  @PatchMapping("/admin/reports/appeals/{id:\\d+}")
  @ResponseBody
  public AppealResponse reviewAppeal(
      @PathVariable Integer id, Authentication auth, @RequestBody ReviewAppealRequest request) {
    return reports.reviewAppeal(id, admin(auth).getUserId(), request);
  }

  @GetMapping("/admin/reports/moderation-history/data")
  @ResponseBody
  public Page<ModerationActionResponse> historyData(@RequestParam(defaultValue = "0") int page) {
    return reports.history(
        PageRequest.of(Math.max(0, page), PAGE_SIZE, Sort.by("createdAt").descending()));
  }

  private String queue(Model model, String title, String activePage, ReportType fixedType) {
    model.addAttribute("pageTitle", title);
    model.addAttribute("activePage", activePage);
    model.addAttribute("fixedType", fixedType == null ? "" : fixedType.name());
    model.addAttribute("reasons", ReportReasonCode.values());
    return "admin/report";
  }

  private long count(ReportStatus status) {
    return reports
        .list(null, status, null, null, null, null, null, null, PageRequest.of(0, 1))
        .getTotalElements();
  }

  private User admin(Authentication auth) {
    if (auth == null) throw new IllegalStateException("Admin authentication is required");
    return users
        .findByEmailIgnoreCase(auth.getName())
        .orElseThrow(() -> new IllegalStateException("Admin account not found"));
  }

  private String activePage(ReportType type) {
    return switch (type) {
      case PROFILE -> "reports-profiles";
      case POST -> "reports-posts";
      case COMMENT -> "reports-comments";
    };
  }

  private void addReturnDestination(Model model, ReportType type) {
    model.addAttribute("returnUrl", switch (type) {
      case PROFILE -> "/admin/reports/profiles";
      case POST -> "/admin/reports/posts";
      case COMMENT -> "/admin/reports/comments";
    });
    model.addAttribute("returnLabel", switch (type) {
      case PROFILE -> "Profile Reports";
      case POST -> "Post Reports";
      case COMMENT -> "Comment Reports";
    });
  }

  public record ReportSummary(
      long total, long pending, long underReview, long resolved, long dismissed) {}
}
