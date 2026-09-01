package com.nhamhealth.nhamhealth_api.controller.api;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.springframework.security.oauth2.jwt.Jwt;

import com.nhamhealth.nhamhealth_api.dto.response.NotificationResponse;
import com.nhamhealth.nhamhealth_api.entity.Notification;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.entity.UserProfile;
import com.nhamhealth.nhamhealth_api.repository.notification.NotificationRepository;
import com.nhamhealth.nhamhealth_api.repository.community.PostCommentRepository;
import com.nhamhealth.nhamhealth_api.repository.notification.PushNotificationDeviceRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserProfileRepository;

class NotificationApiControllerTests {

    @Test
    void includesActorProfileInNotificationResponse() {
        NotificationRepository notifications = mock(NotificationRepository.class);
        PostCommentRepository comments = mock(PostCommentRepository.class);
        UserProfileRepository profiles = mock(UserProfileRepository.class);
        PushNotificationDeviceRepository devices = mock(PushNotificationDeviceRepository.class);
        UserRepository users = mock(UserRepository.class);
        Notification notification = mock(Notification.class);
        User actor = mock(User.class);
        UserProfile profile = mock(UserProfile.class);
        Jwt jwt = mock(Jwt.class);
        LocalDateTime createdAt = LocalDateTime.of(2026, 8, 25, 12, 30);

        when(jwt.getClaim("userId")).thenReturn(42);
        when(notifications.findTop20ByUserUserIdOrderByCreatedAtDesc(42))
                .thenReturn(List.of(notification));
        when(notification.getNotificationId()).thenReturn(8);
        when(notification.getNotificationType()).thenReturn("COMMUNITY");
        when(notification.getTitle()).thenReturn("Maya Chen");
        when(notification.getMessage()).thenReturn("commented on your post.");
        when(notification.getActorUser()).thenReturn(actor);
        when(actor.getUserId()).thenReturn(7);
        when(profiles.findByUser_UserId(7)).thenReturn(Optional.of(profile));
        when(profile.getProfileImageUrl()).thenReturn("/uploads/profiles/maya.jpg");
        when(notification.getReferenceType()).thenReturn("POST");
        when(notification.getReferenceId()).thenReturn(91);
        when(notification.getIsRead()).thenReturn(false);
        when(notification.getCreatedAt()).thenReturn(createdAt);

        NotificationApiController controller = new NotificationApiController(
            notifications, comments, profiles, devices, users);
        NotificationResponse response = controller.list(jwt).getFirst();

        assertEquals(7, response.actorUserId());
        assertEquals("/uploads/profiles/maya.jpg", response.actorAvatarUrl());
        assertEquals("POST", response.referenceType());
        assertEquals(91, response.referenceId());
    }
}
