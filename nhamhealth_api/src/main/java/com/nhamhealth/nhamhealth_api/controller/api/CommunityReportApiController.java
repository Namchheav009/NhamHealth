package com.nhamhealth.nhamhealth_api.controller.api;

import static org.springframework.http.HttpStatus.CREATED;
import static org.springframework.http.HttpStatus.UNAUTHORIZED;

import com.nhamhealth.nhamhealth_api.dto.request.CreatePostReportRequest;
import com.nhamhealth.nhamhealth_api.dto.request.CreateReportRequest;
import com.nhamhealth.nhamhealth_api.dto.response.ReportResponse;
import com.nhamhealth.nhamhealth_api.entity.ReportType;
import com.nhamhealth.nhamhealth_api.service.community.ReportModerationService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.Collection;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.MediaType;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/community")
public class CommunityReportApiController {
  private final ReportModerationService service;

  public CommunityReportApiController(ReportModerationService service) {
    this.service = service;
  }

  @PostMapping(value = "/posts/{postId}/reports", consumes = MediaType.APPLICATION_JSON_VALUE)
  @ResponseStatus(CREATED)
  public ReportResponse create(
      @AuthenticationPrincipal Jwt jwt,
      @PathVariable Integer postId,
      @Valid @RequestBody CreatePostReportRequest request) {
    return service.create(
        userId(jwt),
        new CreateReportRequest(ReportType.POST, postId, request.reason(), request.description()));
  }

  @PostMapping(value = "/posts/{postId}/reports", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
  @ResponseStatus(CREATED)
  public ReportResponse createWithImages(
      @AuthenticationPrincipal Jwt jwt,
      @PathVariable Integer postId,
      @Valid @RequestPart("report") CreatePostReportRequest request,
      @RequestPart(value = "images", required = false) List<MultipartFile> images) {
    return service.create(
        userId(jwt),
        new CreateReportRequest(ReportType.POST, postId, request.reason(), request.description()),
        images == null ? List.of() : images);
  }

  @GetMapping("/reports/me")
  public Page<ReportResponse> mine(
      @AuthenticationPrincipal Jwt jwt,
      @PageableDefault(size = 50, sort = "createdAt", direction = Sort.Direction.DESC)
          Pageable pageable) {
    return service.mine(userId(jwt), pageable);
  }

  @GetMapping("/reports/{id}")
  public ReportResponse detail(@AuthenticationPrincipal Jwt jwt, @PathVariable Integer id) {
    return service.viewerDetail(userId(jwt), id, isAdmin(jwt));
  }

  private boolean isAdmin(Jwt jwt) {
    Object roles = jwt == null ? null : jwt.getClaim("roles");
    return roles instanceof Collection<?> values
        && values.stream().map(String::valueOf).anyMatch("ADMIN"::equalsIgnoreCase);
  }

  private Integer userId(Jwt jwt) {
    if (jwt == null) throw new ResponseStatusException(UNAUTHORIZED, "Authentication is required");
    Number id = jwt.getClaim("userId");
    if (id == null) throw new ResponseStatusException(UNAUTHORIZED, "The access token has no user ID");
    return id.intValue();
  }
}
