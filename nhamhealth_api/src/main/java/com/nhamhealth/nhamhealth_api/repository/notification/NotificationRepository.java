package com.nhamhealth.nhamhealth_api.repository.notification;

import java.util.List;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.nhamhealth.nhamhealth_api.entity.Notification;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, Integer> {
    @EntityGraph(attributePaths = "user")
    List<Notification> findAllByOrderByCreatedAtDesc();

    long countByIsReadFalse();

    long countByUserUserIdAndIsReadFalse(Integer userId);

    List<Notification> findTop20ByUserUserIdOrderByCreatedAtDesc(Integer userId);

    java.util.Optional<Notification> findByNotificationIdAndUserUserId(Integer notificationId, Integer userId);
}
