package com.nhamhealth.nhamhealth_api.repository;

import java.time.LocalDateTime;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.Message;

public interface MessageRepository extends JpaRepository<Message, Integer> {
    long countByChatChatIdAndDeletedAtIsNull(Integer chatId);

    long countByCreatedAtGreaterThanEqualAndDeletedAtIsNull(LocalDateTime since);
}
