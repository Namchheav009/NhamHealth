package com.nhamhealth.nhamhealth_api.controller.api;

import static org.springframework.http.HttpStatus.UNAUTHORIZED;

import com.nhamhealth.nhamhealth_api.dto.request.*;
import com.nhamhealth.nhamhealth_api.dto.response.*;
import com.nhamhealth.nhamhealth_api.entity.*;
import com.nhamhealth.nhamhealth_api.service.community.ReportModerationService;
import jakarta.validation.Valid;
import java.time.LocalDateTime;
import org.springframework.data.domain.*;
import org.springframework.data.web.PageableDefault;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/admin")
public class AdminReportApiController {
  private final ReportModerationService service;

  public AdminReportApiController(ReportModerationService service) {
    this.service = service;
  }

  @GetMapping("/reports")
  public Page<AdminReportResponse> list(
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
      @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC)
          Pageable pageable) {
    return service.list(type, status, reason, severity, reportedUserId, search, from, to, pageable);
  }

  @GetMapping("/reports/{id}")
  public AdminReportResponse detail(@PathVariable Integer id) {
    return service.detail(id);
  }

  @PatchMapping("/reports/{id}/start-review")
  public AdminReportResponse start(
      @AuthenticationPrincipal Jwt jwt,
      @PathVariable Integer id,
      @Valid @RequestBody(required = false) ReviewReportRequest request) {
    return service.startReview(id, userId(jwt), request);
  }

  @PatchMapping("/reports/{id}/dismiss")
  public AdminReportResponse dismiss(
      @AuthenticationPrincipal Jwt jwt,
      @PathVariable Integer id,
      @Valid @RequestBody(required = false) ReviewReportRequest request) {
    return service.dismiss(id, userId(jwt), request);
  }

  @PostMapping("/reports/{id}/actions")
  public ModerationActionResponse action(
      @AuthenticationPrincipal Jwt jwt,
      @PathVariable Integer id,
      @Valid @RequestBody ModerationActionRequest request) {
    return service.act(id, userId(jwt), request);
  }

  @GetMapping("/moderation-history")
  public Page<ModerationActionResponse> history(@PageableDefault(size = 20) Pageable pageable) {
    return service.history(pageable);
  }

  @GetMapping("/appeals")
  public Page<AppealResponse> appeals(
      @RequestParam(required = false) AppealStatus status,
      @PageableDefault(size = 20) Pageable pageable) {
    return service.appeals(status, pageable);
  }

  @PatchMapping("/appeals/{id}")
  public AppealResponse reviewAppeal(
      @AuthenticationPrincipal Jwt jwt,
      @PathVariable Integer id,
      @Valid @RequestBody ReviewAppealRequest request) {
    return service.reviewAppeal(id, userId(jwt), request);
  }

  private Integer userId(Jwt jwt) {
    if (jwt == null) throw new ResponseStatusException(UNAUTHORIZED, "Authentication is required");
    Number id = jwt.getClaim("userId");
    if (id == null)
      throw new ResponseStatusException(UNAUTHORIZED, "The access token has no user ID");
    return id.intValue();
  }
}
