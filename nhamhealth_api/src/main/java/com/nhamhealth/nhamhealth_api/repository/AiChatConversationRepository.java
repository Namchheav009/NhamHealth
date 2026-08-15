package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.AiChatConversation;

public interface AiChatConversationRepository extends JpaRepository<AiChatConversation, Integer> {
    List<AiChatConversation> findAllByOrderByUpdatedAtDesc();

    long countByIsActiveTrue();
}
