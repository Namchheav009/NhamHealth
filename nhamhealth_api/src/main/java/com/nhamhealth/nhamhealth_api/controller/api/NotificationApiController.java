package com.nhamhealth.nhamhealth_api.controller.api;

import static org.springframework.http.HttpStatus.UNAUTHORIZED;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import com.nhamhealth.nhamhealth_api.dto.response.NotificationResponse;
import com.nhamhealth.nhamhealth_api.dto.request.PushDeviceRequest;
import com.nhamhealth.nhamhealth_api.entity.PushNotificationDevice;
import com.nhamhealth.nhamhealth_api.entity.Notification;
import com.nhamhealth.nhamhealth_api.repository.NotificationRepository;
import com.nhamhealth.nhamhealth_api.repository.PostCommentRepository;
import com.nhamhealth.nhamhealth_api.repository.PushNotificationDeviceRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;
import com.nhamhealth.nhamhealth_api.repository.UserProfileRepository;
import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/v1/notifications")
public class NotificationApiController {
    private final NotificationRepository repository;
    private final PostCommentRepository comments;
    private final UserProfileRepository profiles;
    private final PushNotificationDeviceRepository devices;
    private final UserRepository users;

    public NotificationApiController(NotificationRepository repository, PostCommentRepository comments,
            UserProfileRepository profiles, PushNotificationDeviceRepository devices, UserRepository users) {
        this.repository = repository;
        this.comments = comments;
        this.profiles = profiles;
        this.devices = devices;
        this.users = users;
    }

    @PutMapping("/devices")
    @Transactional
    public ResponseEntity<Void> registerDevice(@AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody PushDeviceRequest request) {
        var user = users.findById(userId(jwt))
                .orElseThrow(() -> new ResponseStatusException(UNAUTHORIZED, "User was not found."));
        var device = devices.findByToken(request.token().trim()).orElseGet(PushNotificationDevice::new);
        device.setUser(user);
        device.setToken(request.token().trim());
        device.setPlatform(request.platform().trim().toUpperCase());
        device.setUpdatedAt(LocalDateTime.now());
        devices.save(device);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/devices")
    @Transactional
    public ResponseEntity<Void> unregisterDevice(@AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody PushDeviceRequest request) {
        devices.deleteByTokenAndUserUserId(request.token().trim(), userId(jwt));
        return ResponseEntity.noContent().build();
    }

    @GetMapping
    @Transactional(readOnly = true)
    public List<NotificationResponse> list(@AuthenticationPrincipal Jwt jwt) {
        return repository.findTop20ByUserUserIdOrderByCreatedAtDesc(userId(jwt))
                .stream().map(this::response).toList();
    }

    @GetMapping("/unread-count")
    public Map<String, Long> unreadCount(@AuthenticationPrincipal Jwt jwt) {
        return Map.of("count", repository.countByUserUserIdAndIsReadFalse(userId(jwt)));
    }

    @PatchMapping("/{notificationId}/read")
    @Transactional
    public ResponseEntity<NotificationResponse> markRead(@AuthenticationPrincipal Jwt jwt,
            @PathVariable Integer notificationId) {
        return repository.findByNotificationIdAndUserUserId(notificationId, userId(jwt))
                .map(notification -> {
                    if (!Boolean.TRUE.equals(notification.getIsRead())) {
                        notification.setIsRead(true);
                        notification.setReadAt(LocalDateTime.now());
                        repository.save(notification);
                    }
                    return ResponseEntity.ok(response(notification));
                }).orElseGet(() -> ResponseEntity.notFound().build());
    }

    private NotificationResponse response(Notification notification) {
        Integer actorUserId = notification.getActorUser() == null
                ? null
                : notification.getActorUser().getUserId();
        String actorAvatarUrl = actorUserId == null
                ? ""
                : profiles.findByUser_UserId(actorUserId)
                        .map(profile -> profile.getProfileImageUrl() == null ? "" : profile.getProfileImageUrl())
                        .orElse("");
        String referenceType = notification.getReferenceType();
        Integer referenceId = notification.getReferenceId();
        if ("COMMENT".equalsIgnoreCase(referenceType) && referenceId != null) {
            var comment = comments.findById(referenceId);
            if (comment.isPresent()) {
                referenceType = "POST";
                referenceId = comment.get().getPost().getPostId();
            }
        }
        return new NotificationResponse(notification.getNotificationId(), notification.getNotificationType(),
                notification.getTitle(), notification.getMessage(), actorUserId, actorAvatarUrl,
                referenceType, referenceId,
                Boolean.TRUE.equals(notification.getIsRead()),
                notification.getCreatedAt());
    }

    private Integer userId(Jwt jwt) {
        if (jwt == null) throw new ResponseStatusException(UNAUTHORIZED, "Authentication is required.");
        Number value = jwt.getClaim("userId");
        if (value == null) throw new ResponseStatusException(UNAUTHORIZED, "The access token has no user ID.");
        return value.intValue();
    }
}
