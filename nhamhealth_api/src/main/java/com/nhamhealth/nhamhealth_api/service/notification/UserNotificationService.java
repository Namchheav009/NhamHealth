package com.nhamhealth.nhamhealth_api.service.notification;

import java.time.LocalDateTime;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.nhamhealth.nhamhealth_api.dto.response.AiFoodAnalysisResponse;
import com.nhamhealth.nhamhealth_api.entity.Notification;
import com.nhamhealth.nhamhealth_api.repository.notification.NotificationRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;

@Service
public class UserNotificationService {
    private final UserRepository users;
    private final NotificationRepository notifications;
    private final PushNotificationService pushNotifications;

    public UserNotificationService(UserRepository users, NotificationRepository notifications,
            PushNotificationService pushNotifications) {
        this.users = users;
        this.notifications = notifications;
        this.pushNotifications = pushNotifications;
    }

    @Transactional
    public void passwordChanged(Integer userId) {
        create(userId, "SYSTEM", "Password changed",
                "Your NhamHealth password was changed successfully. If this was not you, secure your account now.",
                "SECURITY", null);
    }

    @Transactional
    public void aiFoodAnalysisCompleted(Integer userId, AiFoodAnalysisResponse result) {
        String title = result.needsUserConfirmation()
                ? "AI food check needs review"
                : "AI food check complete";
        String foodName = result.name() == null || result.name().isBlank()
                ? "your food"
                : result.name().trim();
        String message = result.foodDetected()
                ? foodName + " was analyzed. Open the result to review the nutrition details."
                : "No food was detected. Open AI Food Check and try another clear photo.";
        create(userId, "HEALTH", title, message, "AI_FOOD", result.analysisId());
    }

    private void create(Integer userId, String type, String title, String message,
            String referenceType, Integer referenceId) {
        var user = users.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        Notification notification = new Notification();
        notification.setUser(user);
        notification.setNotificationType(type);
        notification.setTitle(title);
        notification.setMessage(message);
        notification.setReferenceType(referenceType);
        notification.setReferenceId(referenceId);
        notification.setIsRead(false);
        notification.setCreatedAt(LocalDateTime.now());
        pushNotifications.send(notifications.saveAndFlush(notification));
    }
}
