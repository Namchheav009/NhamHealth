package com.nhamhealth.nhamhealth_api.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import com.nhamhealth.nhamhealth_api.entity.ChatParticipant;

public interface ChatParticipantRepository extends JpaRepository<ChatParticipant, Integer> {
    long countByChatChatIdAndLeftAtIsNull(Integer chatId);

    @Query("select count(distinct participant.user.userId) from ChatParticipant participant where participant.leftAt is null")
    long countActiveUsers();
}
