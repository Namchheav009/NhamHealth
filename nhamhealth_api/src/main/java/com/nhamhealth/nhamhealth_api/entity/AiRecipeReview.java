package com.nhamhealth.nhamhealth_api.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

/**
 * Immutable result of an AI readiness check. This replaces a human recipe
 * review: APPROVED recipes may be promoted to Meals, while INCOMPLETE and
 * NOT_SUITABLE recipes remain available in Community only.
 */
@Entity
@Table(name = "ai_recipe_reviews", indexes = {
    @jakarta.persistence.Index(name = "idx_ai_recipe_reviews_recipe_created", columnList = "recipe_id, created_at"),
    @jakarta.persistence.Index(name = "idx_ai_recipe_reviews_status", columnList = "status")
})
public class AiRecipeReview {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ai_recipe_review_id")
    private Integer aiRecipeReviewId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recipe_id", nullable = false)
    private Recipe recipe;

    /** APPROVED, INCOMPLETE, or NOT_SUITABLE. */
    @Column(name = "status", nullable = false, length = 20)
    private String status;

    @Column(name = "summary", length = 1000)
    private String summary;

    /** Machine-readable or display-ready guidance for the author to complete the recipe. */
    @Column(name = "feedback")
    private String feedback;

    @Column(name = "model_name", length = 100)
    private String modelName;

    @Column(name = "model_response")
    private String modelResponse;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    public Integer getAiRecipeReviewId() { return aiRecipeReviewId; }
    public Recipe getRecipe() { return recipe; }
    public void setRecipe(Recipe recipe) { this.recipe = recipe; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getSummary() { return summary; }
    public void setSummary(String summary) { this.summary = summary; }
    public String getFeedback() { return feedback; }
    public void setFeedback(String feedback) { this.feedback = feedback; }
    public String getModelName() { return modelName; }
    public void setModelName(String modelName) { this.modelName = modelName; }
    public String getModelResponse() { return modelResponse; }
    public void setModelResponse(String modelResponse) { this.modelResponse = modelResponse; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
