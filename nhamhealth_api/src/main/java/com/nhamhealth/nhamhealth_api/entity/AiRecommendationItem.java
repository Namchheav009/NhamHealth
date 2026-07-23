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
@Table(name = "ai_recommendation_items")
public class AiRecommendationItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "recommendation_item_id")
    private Integer recommendationItemId;

    @ManyToOne
    @JoinColumn(name = "recommendation_id", nullable = false)
    private AiRecommendation recommendation;

    @ManyToOne
    @JoinColumn(name = "meal_id", nullable = false)
    private Meal meal;

    @Column(name = "rank_order", nullable = false)
    private Integer rankOrder;

    @Column(name = "reason_text", length = 500)
    private String reasonText;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    public AiRecommendationItem() {
    }

    public Integer getRecommendationItemId() {
        return recommendationItemId;
    }

    public AiRecommendation getRecommendation() {
        return recommendation;
    }

    public void setRecommendation(AiRecommendation recommendation) {
        this.recommendation = recommendation;
    }

    public Meal getMeal() {
        return meal;
    }

    public void setMeal(Meal meal) {
        this.meal = meal;
    }

    public Integer getRankOrder() {
        return rankOrder;
    }

    public void setRankOrder(Integer rankOrder) {
        this.rankOrder = rankOrder;
    }

    public String getReasonText() {
        return reasonText;
    }

    public void setReasonText(String reasonText) {
        this.reasonText = reasonText;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
