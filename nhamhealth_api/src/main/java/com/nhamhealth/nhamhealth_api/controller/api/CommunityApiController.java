package com.nhamhealth.nhamhealth_api.controller.api;

import static org.springframework.http.HttpStatus.UNAUTHORIZED;

import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import com.nhamhealth.nhamhealth_api.dto.response.CommunityPersonResponse;
import com.nhamhealth.nhamhealth_api.dto.response.CommunityPostResponse;
import com.nhamhealth.nhamhealth_api.dto.response.CommunityTagResponse;
import com.nhamhealth.nhamhealth_api.dto.response.CommunityCommentResponse;
import com.nhamhealth.nhamhealth_api.dto.response.CommunityReportReasonResponse;
import com.nhamhealth.nhamhealth_api.dto.request.CommunityCommentRequest;
import com.nhamhealth.nhamhealth_api.dto.request.CommunityTagRequest;
import com.nhamhealth.nhamhealth_api.service.CommunityService;
import com.nhamhealth.nhamhealth_api.service.CommunityReportService;

@RestController
@RequestMapping("/api/v1/community")
public class CommunityApiController {
    private final CommunityService service;
    private final CommunityReportService reportService;

    public CommunityApiController(CommunityService service, CommunityReportService reportService) {
        this.service = service;
        this.reportService = reportService;
    }

    @GetMapping("/posts")
    public List<CommunityPostResponse> posts(@AuthenticationPrincipal Jwt jwt,
            @RequestParam(defaultValue = "false") boolean following) {
        return service.posts(userId(jwt), following);
    }

    @GetMapping("/posts/{postId}")
    public CommunityPostResponse post(@AuthenticationPrincipal Jwt jwt, @PathVariable Integer postId) {
        return service.postDetails(userId(jwt), postId);
    }

    @GetMapping("/posts/mine")
    public List<CommunityPostResponse> myPosts(@AuthenticationPrincipal Jwt jwt) {
        return service.myPosts(userId(jwt));
    }

    @GetMapping("/tags")
    public List<CommunityTagResponse> tags(@AuthenticationPrincipal Jwt jwt) {
        userId(jwt);
        return service.tags();
    }

    @PostMapping("/tags")
    @ResponseStatus(HttpStatus.CREATED)
    public CommunityTagResponse createTag(@AuthenticationPrincipal Jwt jwt,
            @jakarta.validation.Valid @RequestBody CommunityTagRequest request) {
        userId(jwt);
        return service.createTag(request.name());
    }

    @GetMapping("/report-reasons")
    public List<CommunityReportReasonResponse> reportReasons(@AuthenticationPrincipal Jwt jwt) {
        userId(jwt);
        return reportService.reasons();
    }

    @PostMapping("/posts/{postId}/reports")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void reportPost(@AuthenticationPrincipal Jwt jwt, @PathVariable Integer postId,
            @RequestParam Integer reasonId) {
        Integer reporterId = userId(jwt);
        service.assertPostVisible(reporterId, postId);
        reportService.reportPost(reporterId, postId, reasonId);
    }

    @PostMapping("/posts/{postId}/comments/{commentId}/reports")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void reportComment(@AuthenticationPrincipal Jwt jwt, @PathVariable Integer postId,
            @PathVariable Integer commentId, @RequestParam Integer reasonId) {
        Integer reporterId = userId(jwt);
        service.assertPostVisible(reporterId, postId);
        reportService.reportComment(reporterId, postId, commentId, reasonId);
    }

    @PostMapping("/posts/{postId}/like")
    public CommunityPostResponse like(@AuthenticationPrincipal Jwt jwt, @PathVariable Integer postId) {
        return service.toggleLike(userId(jwt), postId);
    }

    @GetMapping("/posts/{postId}/comments")
    public List<CommunityCommentResponse> comments(@AuthenticationPrincipal Jwt jwt, @PathVariable Integer postId) {
        return service.comments(userId(jwt), postId);
    }

    @PostMapping("/posts/{postId}/comments")
    @ResponseStatus(HttpStatus.CREATED)
    public CommunityCommentResponse comment(@AuthenticationPrincipal Jwt jwt, @PathVariable Integer postId,
            @RequestBody CommunityCommentRequest request) {
        return service.comment(userId(jwt), postId, request.text(), request.parentCommentId());
    }

    @DeleteMapping("/posts/{postId}/comments/{commentId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteComment(@AuthenticationPrincipal Jwt jwt, @PathVariable Integer postId,
            @PathVariable Integer commentId) {
        service.deleteComment(userId(jwt), postId, commentId);
    }

    @PostMapping("/posts/{postId}/comments/{commentId}/like")
    public CommunityCommentResponse likeComment(@AuthenticationPrincipal Jwt jwt, @PathVariable Integer postId,
            @PathVariable Integer commentId) {
        return service.toggleCommentLike(userId(jwt), postId, commentId);
    }

    @GetMapping("/people")
    public List<CommunityPersonResponse> people(@AuthenticationPrincipal Jwt jwt,
            @RequestParam(defaultValue = "discover") String view) {
        return service.people(userId(jwt), view);
    }

    @PostMapping("/people/{targetUserId}/follow")
    public Map<String, String> follow(@AuthenticationPrincipal Jwt jwt, @PathVariable Integer targetUserId) {
        return Map.of("status", service.toggleFollow(userId(jwt), targetUserId));
    }

    private Integer userId(Jwt jwt) {
        if (jwt == null) throw new ResponseStatusException(UNAUTHORIZED, "Authentication is required.");
        Number value = jwt.getClaim("userId");
        if (value == null) throw new ResponseStatusException(UNAUTHORIZED, "The access token has no user ID.");
        return value.intValue();
    }

    private List<MultipartFile> mergeImages(List<MultipartFile> images, MultipartFile legacyImage) {
        List<MultipartFile> merged = images == null ? new java.util.ArrayList<>() : new java.util.ArrayList<>(images);
        if (legacyImage != null && !legacyImage.isEmpty()) merged.add(legacyImage);
        return merged;
    }
}
