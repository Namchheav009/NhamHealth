package com.nhamhealth.nhamhealth_api.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import com.nhamhealth.nhamhealth_api.entity.Notification;
import com.nhamhealth.nhamhealth_api.entity.Post;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.entity.UserProfile;
import com.nhamhealth.nhamhealth_api.repository.NotificationRepository;
import com.nhamhealth.nhamhealth_api.repository.UserProfileRepository;

class CommunityNotificationServiceTests {

    @Test
    void createsUnreadCommunityNotificationForPostLike() {
        NotificationRepository notifications = mock(NotificationRepository.class);
        UserProfileRepository profiles = mock(UserProfileRepository.class);
        PushNotificationService pushNotifications = mock(PushNotificationService.class);
        CommunityNotificationService service = new CommunityNotificationService(
            notifications, profiles, pushNotifications);
        User actor = user(7);
        User recipient = user(11);
        Post post = mock(Post.class);
        UserProfile profile = mock(UserProfile.class);

        when(post.getPostId()).thenReturn(23);
        when(post.getUser()).thenReturn(recipient);
        when(profile.getFullName()).thenReturn("Maya Chen");
        when(profiles.findByUser_UserId(7)).thenReturn(Optional.of(profile));

        service.postLiked(actor, post);

        ArgumentCaptor<Notification> captor = ArgumentCaptor.forClass(Notification.class);
        verify(notifications).saveAndFlush(captor.capture());
        Notification saved = captor.getValue();
        assertSame(recipient, saved.getUser());
        assertSame(actor, saved.getActorUser());
        assertEquals("COMMUNITY", saved.getNotificationType());
        assertEquals("POST", saved.getReferenceType());
        assertEquals(23, saved.getReferenceId());
        assertEquals("Maya Chen", saved.getTitle());
        assertEquals("liked your post.", saved.getMessage());
        assertFalse(saved.getIsRead());
        assertNotNull(saved.getCreatedAt());
    }

    @Test
    void doesNotCreateNotificationForSelfActivity() {
        NotificationRepository notifications = mock(NotificationRepository.class);
        UserProfileRepository profiles = mock(UserProfileRepository.class);
        PushNotificationService pushNotifications = mock(PushNotificationService.class);
        CommunityNotificationService service = new CommunityNotificationService(
            notifications, profiles, pushNotifications);
        User actor = user(7);
        Post post = mock(Post.class);

        when(post.getPostId()).thenReturn(23);
        when(post.getUser()).thenReturn(actor);

        service.postLiked(actor, post);

        verifyNoInteractions(notifications, profiles);
    }

    @Test
    void followCreatesNotificationAndSendsDevicePush() {
        NotificationRepository notifications = mock(NotificationRepository.class);
        UserProfileRepository profiles = mock(UserProfileRepository.class);
        PushNotificationService pushNotifications = mock(PushNotificationService.class);
        CommunityNotificationService service = new CommunityNotificationService(
            notifications, profiles, pushNotifications);
        User actor = user(7);
        User recipient = user(11);
        UserProfile profile = mock(UserProfile.class);

        when(profile.getFullName()).thenReturn("Maya Chen");
        when(profiles.findByUser_UserId(7)).thenReturn(Optional.of(profile));
        when(notifications.saveAndFlush(org.mockito.ArgumentMatchers.any(Notification.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        service.followed(actor, recipient);

        ArgumentCaptor<Notification> captor = ArgumentCaptor.forClass(Notification.class);
        verify(notifications).saveAndFlush(captor.capture());
        Notification saved = captor.getValue();
        assertSame(recipient, saved.getUser());
        assertSame(actor, saved.getActorUser());
        assertEquals("COMMUNITY", saved.getNotificationType());
        assertEquals("USER", saved.getReferenceType());
        assertEquals(7, saved.getReferenceId());
        assertEquals("Maya Chen", saved.getTitle());
        assertEquals("started following you.", saved.getMessage());
        assertFalse(saved.getIsRead());
        verify(pushNotifications).send(saved);
    }

    private User user(int id) {
        User user = mock(User.class);
        when(user.getUserId()).thenReturn(id);
        return user;
    }
}
