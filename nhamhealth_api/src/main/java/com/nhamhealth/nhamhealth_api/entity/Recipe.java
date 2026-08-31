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
 * A user-authored meal post. The meal information is the aggregate root;
 * ingredients and cooking steps are its children. The historical Java name
 * remains temporarily for API compatibility, but there is no standalone
 * recipe record.
 */
@Entity
@Table(name = "user_meal_posts", indexes = {
    @jakarta.persistence.Index(name = "idx_user_meal_posts_author_user_id", columnList = "author_user_id"),
    @jakarta.persistence.Index(name = "idx_user_meal_posts_status_updated_at", columnList = "status, updated_at")
})
public class Recipe {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "user_meal_post_id")
    private Integer recipeId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "author_user_id", nullable = false)
    private User author;

    /** The category selected by the author for the eventual catalog meal. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id")
    private MealCategory category;

    @Column(name = "recipe_name", nullable = false, length = 150)
    private String recipeName;

    @Column(name = "description")
    private String description;

    @Column(name = "main_image_url")
    private String mainImageUrl;

    @Column(name = "cooking_time_minutes")
    private Integer cookingTimeMinutes;

    @Column(name = "servings")
    private Integer servings;

    @Column(name = "difficulty", length = 20)
    private String difficulty;

    @Column(name = "ai_status", nullable = false, length = 20)
    private String aiStatus = "PENDING";

    @Column(name = "ai_review_reason")
    private String aiReviewReason;

    @jakarta.persistence.OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "meal_id", unique = true)
    private Meal meal;

    /** DRAFT, PUBLISHED, or ARCHIVED. */
    @Column(name = "status", nullable = false, length = 20)
    private String status = "DRAFT";

    @Column(name = "published_at")
    private LocalDateTime publishedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    public Integer getRecipeId() { return recipeId; }
    public User getAuthor() { return author; }
    public void setAuthor(User author) { this.author = author; }
    public MealCategory getCategory() { return category; }
    public void setCategory(MealCategory category) { this.category = category; }
    public String getRecipeName() { return recipeName; }
    public void setRecipeName(String recipeName) { this.recipeName = recipeName; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getMainImageUrl() { return mainImageUrl; }
    public void setMainImageUrl(String mainImageUrl) { this.mainImageUrl = mainImageUrl; }
    public Integer getCookingTimeMinutes() { return cookingTimeMinutes; }
    public void setCookingTimeMinutes(Integer cookingTimeMinutes) { this.cookingTimeMinutes = cookingTimeMinutes; }
    public Integer getServings() { return servings; }
    public void setServings(Integer servings) { this.servings = servings; }
    public String getDifficulty() { return difficulty; }
    public void setDifficulty(String difficulty) { this.difficulty = difficulty; }
    public String getAiStatus() { return aiStatus; }
    public void setAiStatus(String aiStatus) { this.aiStatus = aiStatus; }
    public String getAiReviewReason() { return aiReviewReason; }
    public void setAiReviewReason(String aiReviewReason) { this.aiReviewReason = aiReviewReason; }
    public Meal getMeal() { return meal; }
    public void setMeal(Meal meal) { this.meal = meal; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public LocalDateTime getPublishedAt() { return publishedAt; }
    public void setPublishedAt(LocalDateTime publishedAt) { this.publishedAt = publishedAt; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
