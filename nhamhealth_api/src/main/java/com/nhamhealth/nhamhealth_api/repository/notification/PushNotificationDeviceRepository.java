package com.nhamhealth.nhamhealth_api.repository.notification;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.PushNotificationDevice;

public interface PushNotificationDeviceRepository extends JpaRepository<PushNotificationDevice, Long> {
    Optional<PushNotificationDevice> findByToken(String token);
    List<PushNotificationDevice> findByUserUserId(Integer userId);
    void deleteByTokenAndUserUserId(String token, Integer userId);
}
