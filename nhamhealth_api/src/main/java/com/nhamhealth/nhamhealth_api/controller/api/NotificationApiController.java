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
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import com.nhamhealth.nhamhealth_api.dto.response.NotificationResponse;
import com.nhamhealth.nhamhealth_api.entity.Notification;
import com.nhamhealth.nhamhealth_api.repository.NotificationRepository;

@RestController
@RequestMapping("/api/v1/notifications")
public class NotificationApiController {
    private final NotificationRepository repository;

    public NotificationApiController(NotificationRepository repository) {
        this.repository = repository;
    }

    @GetMapping
    @Transactional(readOnly = true)
    public List<NotificationResponse> list(@AuthenticationPrincipal Jwt jwt) {
        return repository.findAllByUserUserIdOrderByCreatedAtDesc(userId(jwt))
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
        return new NotificationResponse(notification.getNotificationId(), notification.getNotificationType(),
                notification.getTitle(), notification.getMessage(), Boolean.TRUE.equals(notification.getIsRead()),
                notification.getCreatedAt());
    }

    private Integer userId(Jwt jwt) {
        if (jwt == null) throw new ResponseStatusException(UNAUTHORIZED, "Authentication is required.");
        Number value = jwt.getClaim("userId");
        if (value == null) throw new ResponseStatusException(UNAUTHORIZED, "The access token has no user ID.");
        return value.intValue();
    }
}
