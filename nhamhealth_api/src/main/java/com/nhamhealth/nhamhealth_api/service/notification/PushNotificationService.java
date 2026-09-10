package com.nhamhealth.nhamhealth_api.service.notification;

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
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.MessagingErrorCode;
import com.nhamhealth.nhamhealth_api.entity.Notification;
import com.nhamhealth.nhamhealth_api.repository.notification.PushNotificationDeviceRepository;

@Service
public class PushNotificationService {
    private static final Logger log = LoggerFactory.getLogger(PushNotificationService.class);
    private final ObjectProvider<FirebaseMessaging> messaging;
    private final PushNotificationDeviceRepository devices;

    public PushNotificationService(ObjectProvider<FirebaseMessaging> messaging,
            PushNotificationDeviceRepository devices) {
        this.messaging = messaging;
        this.devices = devices;
    }

    public void send(Notification notification) {
        if (TransactionSynchronizationManager.isActualTransactionActive()
                && TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    try {
                        sendNow(notification);
                    } catch (RuntimeException error) {
                        // Push delivery is best-effort. The database action has
                        // already committed and must not be reported to the app
                        // as a failed request because Firebase or a device-token
                        // lookup is temporarily unavailable.
                        log.warn("Unable to deliver push notification after commit", error);
                    }
                }
            });
            return;
        }
        sendNow(notification);
    }

    public void broadcast(String title, String message, String referenceType, String referenceId,
            String avatarUrl, String subText) {
        var firebase = messaging.getIfAvailable();
        if (firebase == null) {
            log.info("Firebase Cloud Messaging is not configured; skipping push broadcast.");
            return;
        }

        var data = new java.util.HashMap<String, String>();
        data.put("notificationId", String.valueOf((int) (System.currentTimeMillis() & 0x7FFFFFFF)));
        data.put("title", value(title));
        data.put("body", value(message));
        data.put("referenceType", value(referenceType));
        data.put("referenceId", value(referenceId));
        if (avatarUrl != null && !avatarUrl.isBlank())
            data.put("avatarUrl", avatarUrl);
        if (subText != null && !subText.isBlank())
            data.put("subText", subText);

        var notifBuilder = com.google.firebase.messaging.Notification.builder()
                .setTitle(title)
                .setBody(message);
        if (avatarUrl != null && !avatarUrl.isBlank()) {
            notifBuilder.setImage(avatarUrl);
        }

        // 1. Broadcast to all Android devices subscribed to 'all_devices' topic
        var topicMessage = Message.builder()
                .setTopic("all_devices")
                .setNotification(notifBuilder.build())
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
            String response = firebase.send(topicMessage);
            log.info("Real-time push broadcast sent to topic 'all_devices': {}", response);
        } catch (FirebaseMessagingException error) {
            log.warn("Unable to broadcast to topic 'all_devices'", error);
        }

        // 2. Also send directly to all registered device tokens
        for (var device : devices.findAll()) {
            var directMessage = Message.builder()
                    .setToken(device.getToken())
                    .setNotification(notifBuilder.build())
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
                firebase.send(directMessage);
            } catch (FirebaseMessagingException error) {
                if (error.getMessagingErrorCode() == MessagingErrorCode.UNREGISTERED) {
                    devices.delete(device);
                }
            }
        }
    }

    private void sendNow(Notification notification) {
        var firebase = messaging.getIfAvailable();
        if (firebase == null)
            return;
        var data = new java.util.HashMap<String, String>();
        data.put("notificationId", notification.getNotificationId().toString());
        data.put("title", value(notification.getTitle()));
        data.put("body", value(notification.getMessage()));
        data.put("referenceType", value(notification.getReferenceType()));
        data.put("referenceId", notification.getReferenceId() == null ? "" : notification.getReferenceId().toString());

        if (notification.getActorUser() != null) {
            String actorName = notification.getActorUser().getName();
            if (actorName != null && !actorName.isBlank()) {
                data.put("subText", actorName);
            }
        }

        var notifBuilder = com.google.firebase.messaging.Notification.builder()
                .setTitle(notification.getTitle())
                .setBody(notification.getMessage());

        for (var device : devices.findByUserUserId(notification.getUser().getUserId())) {
            var message = Message.builder()
                    .setToken(device.getToken())
                    .setNotification(notifBuilder.build())
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

    private String value(String value) {
        return value == null ? "" : value;
    }
}
