package com.nhamhealth.nhamhealth_api.controller.admin;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

import com.nhamhealth.nhamhealth_api.dto.request.AdminCreateNotificationRequest;
import com.nhamhealth.nhamhealth_api.entity.Notification;
import com.nhamhealth.nhamhealth_api.repository.NotificationRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;

import jakarta.validation.Valid;

@Controller
public class NotificationAdminController {

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;

    public NotificationAdminController(NotificationRepository notificationRepository, UserRepository userRepository) {
        this.notificationRepository = notificationRepository;
        this.userRepository = userRepository;
    }

    @GetMapping("/admin/notifications")
    public String notificationsPage(Authentication authentication, Model model) {
        List<Notification> notifs = notificationRepository.findAllByOrderByCreatedAtDesc();
        LocalDateTime lastDay = LocalDateTime.now().minusHours(24);
        model.addAttribute("pageTitle", "Notifications");
        model.addAttribute("activePage", "notifications");
        model.addAttribute("adminName", authentication != null ? authentication.getName() : "admin");
        model.addAttribute("notifications", notifs);
        model.addAttribute("totalNotifications", notifs.size());
        model.addAttribute("unreadNotifications", notifs.stream()
                .filter(notification -> !Boolean.TRUE.equals(notification.getIsRead())).count());
        model.addAttribute("recentNotifications", notifs.stream()
                .filter(notification -> notification.getCreatedAt() != null
                        && !notification.getCreatedAt().isBefore(lastDay)).count());
        return "admin/notification";
    }

    @PostMapping("/admin/notifications")
    public ResponseEntity<?> createNotification(@Valid @RequestBody AdminCreateNotificationRequest request) {
        return userRepository.findByEmailIgnoreCase(request.userEmail().trim())
                .<ResponseEntity<?>>map(user -> {
                    Notification notification = new Notification();
                    notification.setUser(user);
                    notification.setNotificationType(request.notificationType().trim().toUpperCase());
                    notification.setTitle(request.title().trim());
                    notification.setMessage(request.message().trim());
                    notification.setIsRead(false);
                    notification.setCreatedAt(LocalDateTime.now());
                    Notification saved = notificationRepository.save(notification);
                    return ResponseEntity.ok(Map.of("id", saved.getNotificationId()));
                })
                .orElseGet(() -> ResponseEntity.badRequest()
                        .body(Map.of("message", "No user exists with that email address")));
    }

    @PatchMapping("/admin/notifications/{notificationId}/read")
    public ResponseEntity<?> updateReadStatus(
            @PathVariable Integer notificationId,
            @RequestBody Map<String, Boolean> request) {
        return notificationRepository.findById(notificationId)
                .<ResponseEntity<?>>map(notification -> {
                    boolean isRead = Boolean.TRUE.equals(request.get("read"));
                    notification.setIsRead(isRead);
                    notification.setReadAt(isRead ? LocalDateTime.now() : null);
                    notificationRepository.save(notification);
                    return ResponseEntity.ok(Map.of("read", isRead));
                })
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @DeleteMapping("/admin/notifications/{notificationId}")
    public ResponseEntity<?> deleteNotification(@PathVariable Integer notificationId) {
        if (!notificationRepository.existsById(notificationId)) {
            return ResponseEntity.notFound().build();
        }
        notificationRepository.deleteById(notificationId);
        return ResponseEntity.noContent().build();
    }
}
