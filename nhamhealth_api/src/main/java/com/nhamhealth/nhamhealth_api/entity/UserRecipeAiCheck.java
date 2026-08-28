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

/** Audit trail of each author's AI recipe-check request and its result. */
@Entity
@Table(name = "user_recipe_ai_checks", indexes = {
    @jakarta.persistence.Index(name = "idx_user_recipe_ai_checks_user_created", columnList = "user_id, created_at"),
    @jakarta.persistence.Index(name = "idx_user_recipe_ai_checks_recipe_created", columnList = "recipe_id, created_at")
})
public class UserRecipeAiCheck {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "user_recipe_ai_check_id")
    private Integer userRecipeAiCheckId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recipe_id", nullable = false)
    private Recipe recipe;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ai_recipe_review_id")
    private AiRecipeReview aiRecipeReview;

    @Column(name = "status", nullable = false, length = 20)
    private String status;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    public Integer getUserRecipeAiCheckId() { return userRecipeAiCheckId; }
    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }
    public Recipe getRecipe() { return recipe; }
    public void setRecipe(Recipe recipe) { this.recipe = recipe; }
    public AiRecipeReview getAiRecipeReview() { return aiRecipeReview; }
    public void setAiRecipeReview(AiRecipeReview aiRecipeReview) { this.aiRecipeReview = aiRecipeReview; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
