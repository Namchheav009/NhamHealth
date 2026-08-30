package com.nhamhealth.nhamhealth_api.service;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import com.google.firebase.messaging.FirebaseMessaging;
import com.nhamhealth.nhamhealth_api.entity.Notification;
import com.nhamhealth.nhamhealth_api.repository.PushNotificationDeviceRepository;

class PushNotificationServiceTests {

    @Test
    void sendsOnlyAfterAnActiveTransactionCommits() {
        @SuppressWarnings("unchecked")
        ObjectProvider<FirebaseMessaging> messaging = mock(ObjectProvider.class);
        PushNotificationService service = new PushNotificationService(
                messaging, mock(PushNotificationDeviceRepository.class));

        TransactionSynchronizationManager.initSynchronization();
        TransactionSynchronizationManager.setActualTransactionActive(true);
        try {
            service.send(mock(Notification.class));
            verifyNoInteractions(messaging);

            TransactionSynchronizationManager.getSynchronizations()
                    .forEach(synchronization -> synchronization.afterCommit());

            verify(messaging).getIfAvailable();
        } finally {
            TransactionSynchronizationManager.setActualTransactionActive(false);
            TransactionSynchronizationManager.clearSynchronization();
        }
    }

    @Test
    void sendsImmediatelyWithoutATransaction() {
        @SuppressWarnings("unchecked")
        ObjectProvider<FirebaseMessaging> messaging = mock(ObjectProvider.class);
        PushNotificationService service = new PushNotificationService(
                messaging, mock(PushNotificationDeviceRepository.class));

        service.send(mock(Notification.class));

        verify(messaging).getIfAvailable();
    }
}
