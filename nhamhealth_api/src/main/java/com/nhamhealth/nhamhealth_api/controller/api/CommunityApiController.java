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
import com.nhamhealth.nhamhealth_api.dto.request.CommunityCommentRequest;
import com.nhamhealth.nhamhealth_api.dto.request.SharePostRequest;
import com.nhamhealth.nhamhealth_api.service.CommunityService;

@RestController
@RequestMapping("/api/v1/community")
public class CommunityApiController {
    private final CommunityService service;

    public CommunityApiController(CommunityService service) { this.service = service; }

    @GetMapping("/posts")
    public List<CommunityPostResponse> posts(@AuthenticationPrincipal Jwt jwt,
            @RequestParam(defaultValue = "false") boolean following) {
        return service.posts(userId(jwt), following);
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

    @PostMapping(value = "/posts", consumes = "multipart/form-data")
    @ResponseStatus(HttpStatus.CREATED)
    public CommunityPostResponse create(@AuthenticationPrincipal Jwt jwt,
            @RequestParam(required = false) String title,
            @RequestParam String description,
            @RequestParam(defaultValue = "PUBLIC") String visibility,
            @RequestParam(defaultValue = "true") boolean allowComments,
            @RequestParam(defaultValue = "true") boolean allowReplies,
            @RequestParam(required = false) List<Integer> tagIds,
            @RequestPart(name = "images", required = false) List<MultipartFile> images,
            @RequestPart(name = "image", required = false) MultipartFile image) {
        return service.create(userId(jwt), title, description, visibility, allowComments, allowReplies, tagIds,
                mergeImages(images, image));
    }

    @PutMapping(value = "/posts/{postId}", consumes = "multipart/form-data")
    public CommunityPostResponse update(@AuthenticationPrincipal Jwt jwt, @PathVariable Integer postId,
            @RequestParam(required = false) String title,
            @RequestParam String description,
            @RequestParam(defaultValue = "PUBLIC") String visibility,
            @RequestParam(defaultValue = "true") boolean allowComments,
            @RequestParam(defaultValue = "true") boolean allowReplies,
            @RequestParam(defaultValue = "false") boolean removeImage,
            @RequestParam(required = false) List<Integer> tagIds,
            @RequestPart(name = "images", required = false) List<MultipartFile> images,
            @RequestPart(name = "image", required = false) MultipartFile image) {
        return service.update(userId(jwt), postId, title, description, visibility, allowComments, allowReplies,
                removeImage, tagIds, mergeImages(images, image), image != null && !image.isEmpty());
    }

    @DeleteMapping("/posts/{postId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@AuthenticationPrincipal Jwt jwt, @PathVariable Integer postId) {
        service.delete(userId(jwt), postId);
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

    @PostMapping("/posts/{postId}/comments/{commentId}/like")
    public CommunityCommentResponse likeComment(@AuthenticationPrincipal Jwt jwt, @PathVariable Integer postId,
            @PathVariable Integer commentId) {
        return service.toggleCommentLike(userId(jwt), postId, commentId);
    }

    @PostMapping("/posts/{postId}/share")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void share(@AuthenticationPrincipal Jwt jwt, @PathVariable Integer postId,
            @RequestBody(required = false) SharePostRequest request) {
        service.share(userId(jwt), postId, request == null ? List.of() : request.recipientIds());
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
