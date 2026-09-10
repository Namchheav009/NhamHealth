package com.nhamhealth.nhamhealth_api.service.notification;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import com.nhamhealth.nhamhealth_api.dto.response.AiFoodAnalysisResponse;
import com.nhamhealth.nhamhealth_api.entity.Notification;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.notification.NotificationRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;

class UserNotificationServiceTests {

    @Test
    void createsAndPushesPasswordChangedNotification() {
        Fixture fixture = new Fixture();

        fixture.service.passwordChanged(7);

        Notification saved = fixture.savedNotification();
        assertEquals("SYSTEM", saved.getNotificationType());
        assertEquals("SECURITY", saved.getReferenceType());
        assertEquals("Password changed", saved.getTitle());
        assertFalse(saved.getIsRead());
        verify(fixture.push).send(saved);
    }

    @Test
    void createsAndPushesAiFoodResultNotification() {
        Fixture fixture = new Fixture();
        AiFoodAnalysisResponse result = mock(AiFoodAnalysisResponse.class);
        when(result.analysisId()).thenReturn(42);
        when(result.name()).thenReturn("Chicken rice");
        when(result.foodDetected()).thenReturn(true);

        fixture.service.aiFoodAnalysisCompleted(7, result);

        Notification saved = fixture.savedNotification();
        assertEquals("HEALTH", saved.getNotificationType());
        assertEquals("AI_FOOD", saved.getReferenceType());
        assertEquals(42, saved.getReferenceId());
        assertEquals("AI food check complete", saved.getTitle());
        verify(fixture.push).send(saved);
    }

    private static final class Fixture {
        private final UserRepository users = mock(UserRepository.class);
        private final NotificationRepository notifications = mock(NotificationRepository.class);
        private final PushNotificationService push = mock(PushNotificationService.class);
        private final UserNotificationService service =
                new UserNotificationService(users, notifications, push);

        private Fixture() {
            User user = new User();
            when(users.findById(7)).thenReturn(Optional.of(user));
            when(notifications.saveAndFlush(any(Notification.class)))
                    .thenAnswer(invocation -> invocation.getArgument(0));
        }

        private Notification savedNotification() {
            ArgumentCaptor<Notification> captor = ArgumentCaptor.forClass(Notification.class);
            verify(notifications).saveAndFlush(captor.capture());
            return captor.getValue();
        }
    }
}
