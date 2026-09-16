package com.nhamhealth.nhamhealth_api.controller.api;

import static org.springframework.http.HttpStatus.UNAUTHORIZED;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import com.nhamhealth.nhamhealth_api.dto.request.CreateFollowConnection;
import com.nhamhealth.nhamhealth_api.dto.response.FollowConnectionResponse;
import com.nhamhealth.nhamhealth_api.service.community.FollowConnectionRateLimiter;
import com.nhamhealth.nhamhealth_api.service.community.FollowConnectionService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/follows/connections")
public class FollowConnectionApiController {
    private final FollowConnectionService service;
    private final FollowConnectionRateLimiter rateLimiter;

    public FollowConnectionApiController(FollowConnectionService service, FollowConnectionRateLimiter rateLimiter) {
        this.service = service;
        this.rateLimiter = rateLimiter;
    }

    @PostMapping
    public ResponseEntity<FollowConnectionResponse> create(@AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody CreateFollowConnection request) {
        Integer senderId = userId(jwt);
        rateLimiter.check(senderId);
        FollowConnectionResponse result = service.create(senderId, request.receiverId());
        HttpStatus status = "PENDING".equals(result.status()) ? HttpStatus.CREATED : HttpStatus.OK;
        return ResponseEntity.status(status).body(result);
    }

    @PostMapping("/{requestId}/accept")
    public FollowConnectionResponse accept(@AuthenticationPrincipal Jwt jwt, @PathVariable Integer requestId) {
        return service.accept(userId(jwt), requestId);
    }

    @PostMapping("/{requestId}/decline")
    public FollowConnectionResponse decline(@AuthenticationPrincipal Jwt jwt, @PathVariable Integer requestId) {
        return service.decline(userId(jwt), requestId);
    }

    private Integer userId(Jwt jwt) {
        if (jwt == null) throw new ResponseStatusException(UNAUTHORIZED, "Authentication is required.");
        Number value = jwt.getClaim("userId");
        if (value == null) throw new ResponseStatusException(UNAUTHORIZED, "The access token has no user ID.");
        return value.intValue();
    }
}
