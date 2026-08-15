package com.nhamhealth.nhamhealth_api.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.AiChatMessage;

public interface AiChatMessageRepository extends JpaRepository<AiChatMessage, Integer> {
    Optional<AiChatMessage> findTopByAiChatConversationAiConversationIdOrderByCreatedAtDesc(Integer conversationId);

    long countByAiChatConversationAiConversationId(Integer conversationId);

    void deleteByAiChatConversationAiConversationId(Integer conversationId);
}
