package com.nhamhealth.nhamhealth_api.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

@Entity
@Table(name = "ai_chat_messages")
public class AiChatMessage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ai_message_id")
    private Integer aiMessageId;

    @ManyToOne
    @JoinColumn(name = "ai_conversation_id", nullable = false)
    private AiChatConversation aiChatConversation;

    @Column(name = "sender_type", nullable = false, length = 20)
    private String senderType;

    @Column(name = "message_text", nullable = false)
    private String messageText;

    @ManyToOne
    @JoinColumn(name = "recommendation_id")
    private AiRecommendation recommendation;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    public AiChatMessage() {
    }

    public Integer getAiMessageId() {
        return aiMessageId;
    }

    public AiChatConversation getAiChatConversation() {
        return aiChatConversation;
    }

    public void setAiChatConversation(AiChatConversation aiChatConversation) {
        this.aiChatConversation = aiChatConversation;
    }

    public String getSenderType() {
        return senderType;
    }

    public void setSenderType(String senderType) {
        this.senderType = senderType;
    }

    public String getMessageText() {
        return messageText;
    }

    public void setMessageText(String messageText) {
        this.messageText = messageText;
    }

    public AiRecommendation getRecommendation() {
        return recommendation;
    }

    public void setRecommendation(AiRecommendation recommendation) {
        this.recommendation = recommendation;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
