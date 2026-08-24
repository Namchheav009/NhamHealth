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

    @PostMapping(value = "/posts", consumes = "multipart/form-data")
    @ResponseStatus(HttpStatus.CREATED)
    public CommunityPostResponse create(@AuthenticationPrincipal Jwt jwt,
            @RequestParam(required = false) String title,
            @RequestParam String description,
            @RequestPart(required = false) MultipartFile image) {
        return service.create(userId(jwt), title, description, image);
    }

    @PostMapping("/posts/{postId}/like")
    public CommunityPostResponse like(@AuthenticationPrincipal Jwt jwt, @PathVariable Integer postId) {
        return service.toggleLike(userId(jwt), postId);
    }

    @PostMapping("/posts/{postId}/share")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void share(@AuthenticationPrincipal Jwt jwt, @PathVariable Integer postId) {
        service.share(userId(jwt), postId);
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
}
