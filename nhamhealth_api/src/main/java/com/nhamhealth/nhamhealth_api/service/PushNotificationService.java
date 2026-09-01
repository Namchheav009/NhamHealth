package com.nhamhealth.nhamhealth_api.service;

import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import com.google.firebase.messaging.AndroidConfig;
import com.google.firebase.messaging.AndroidNotification;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.MessagingErrorCode;
import com.google.firebase.messaging.Message;
import com.nhamhealth.nhamhealth_api.entity.Notification;
import com.nhamhealth.nhamhealth_api.repository.PushNotificationDeviceRepository;

@Service
public class PushNotificationService {
    private static final Logger log = LoggerFactory.getLogger(PushNotificationService.class);
    private final ObjectProvider<FirebaseMessaging> messaging;
    private final PushNotificationDeviceRepository devices;

    public PushNotificationService(ObjectProvider<FirebaseMessaging> messaging, PushNotificationDeviceRepository devices) {
        this.messaging = messaging;
        this.devices = devices;
    }

    public void send(Notification notification) {
        if (TransactionSynchronizationManager.isActualTransactionActive()
                && TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    sendNow(notification);
                }
            });
            return;
        }
        sendNow(notification);
    }

    private void sendNow(Notification notification) {
        var firebase = messaging.getIfAvailable();
        if (firebase == null) return;
        var data = Map.of(
                "notificationId", notification.getNotificationId().toString(),
                "title", value(notification.getTitle()),
                "body", value(notification.getMessage()),
                "referenceType", value(notification.getReferenceType()),
                "referenceId", notification.getReferenceId() == null ? "" : notification.getReferenceId().toString());
        for (var device : devices.findByUserUserId(notification.getUser().getUserId())) {
            var message = Message.builder()
                    .setToken(device.getToken())
                    .setNotification(com.google.firebase.messaging.Notification.builder()
                            .setTitle(notification.getTitle())
                            .setBody(notification.getMessage())
                            .build())
                    .putAllData(data)
                    .setAndroidConfig(AndroidConfig.builder()
                            .setPriority(AndroidConfig.Priority.HIGH)
                            .setNotification(AndroidNotification.builder()
                                    .setChannelId("nhamhealth_notifications")
                                    .setSound("default")
                                    .build())
                            .build())
                    .build();
            try {
                firebase.send(message);
            } catch (FirebaseMessagingException error) {
                if (error.getMessagingErrorCode() == MessagingErrorCode.UNREGISTERED) {
                    devices.delete(device);
                    log.info("Removed an expired Firebase device token");
                } else {
                    log.warn("Unable to send push notification", error);
                }
            }
        }
    }

    private String value(String value) { return value == null ? "" : value; }
}
