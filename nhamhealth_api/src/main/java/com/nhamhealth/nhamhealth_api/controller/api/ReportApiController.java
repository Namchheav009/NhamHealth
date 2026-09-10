package com.nhamhealth.nhamhealth_api.controller.api;

import static org.springframework.http.HttpStatus.*;

import com.nhamhealth.nhamhealth_api.dto.request.*;
import com.nhamhealth.nhamhealth_api.dto.response.*;
import com.nhamhealth.nhamhealth_api.service.community.ReportModerationService;
import jakarta.validation.Valid;
import org.springframework.data.domain.*;
import org.springframework.data.web.PageableDefault;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import java.util.Set;
import com.nhamhealth.nhamhealth_api.entity.ReportReasonCode;
import com.nhamhealth.nhamhealth_api.entity.ReportType;
import com.nhamhealth.nhamhealth_api.service.community.ReportModerationPolicy;

@RestController
@RequestMapping("/api/reports")
public class ReportApiController {
  private final ReportModerationService service;
  private final ReportModerationPolicy policy;

  public ReportApiController(ReportModerationService service, ReportModerationPolicy policy) {
    this.service = service;
    this.policy = policy;
  }

  @GetMapping("/reasons")
  public Set<ReportReasonCode> reasons(
      @AuthenticationPrincipal Jwt jwt, @RequestParam ReportType type) {
    userId(jwt);
    return policy.reasonsFor(type);
  }

  @PostMapping
  @ResponseStatus(CREATED)
  public ReportResponse create(
      @AuthenticationPrincipal Jwt jwt, @Valid @RequestBody CreateReportRequest request) {
    return service.create(userId(jwt), request);
  }

  @GetMapping("/my")
  public Page<ReportResponse> mine(
      @AuthenticationPrincipal Jwt jwt,
      @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC)
          Pageable pageable) {
    return service.mine(userId(jwt), pageable);
  }

  @PostMapping("/appeals")
  @ResponseStatus(CREATED)
  public AppealResponse appeal(
      @AuthenticationPrincipal Jwt jwt, @Valid @RequestBody AppealRequest request) {
    return service.appeal(userId(jwt), request);
  }

  private Integer userId(Jwt jwt) {
    if (jwt == null) throw new ResponseStatusException(UNAUTHORIZED, "Authentication is required");
    Number id = jwt.getClaim("userId");
    if (id == null)
      throw new ResponseStatusException(UNAUTHORIZED, "The access token has no user ID");
    return id.intValue();
  }
}
