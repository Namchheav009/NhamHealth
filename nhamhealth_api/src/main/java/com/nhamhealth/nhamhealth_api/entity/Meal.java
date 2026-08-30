package com.nhamhealth.nhamhealth_api.entity;

import com.nhamhealth.nhamhealth_api.entity.User;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "meals", indexes = {
    @jakarta.persistence.Index(name = "idx_meals_category_id", columnList = "category_id"),
    @jakarta.persistence.Index(name = "idx_meals_created_by_user_id", columnList = "created_by_user_id"),
    @jakarta.persistence.Index(name = "idx_meals_updated_at", columnList = "updated_at")
})
public class Meal {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "meal_id")
    private Integer mealId;

    @ManyToOne(fetch = jakarta.persistence.FetchType.LAZY)
    @JoinColumn(name = "category_id", nullable = false)
    private MealCategory category;

    @ManyToOne(fetch = jakarta.persistence.FetchType.LAZY)
    @JoinColumn(name = "created_by_user_id")
    private User createdByUser;

    /** Present only when this catalog meal was promoted from an AI-approved user meal post. */
    @jakarta.persistence.OneToOne(fetch = jakarta.persistence.FetchType.LAZY)
    @JoinColumn(name = "source_user_meal_post_id", unique = true)
    private Recipe sourceRecipe;

    /** ADMIN for curated meals and COMMUNITY for a promoted recipe. */
    @Column(name = "source_type", nullable = false, length = 20)
    private String sourceType = "ADMIN";

    /** ADMIN for curated meals and AI for a community recipe approved by AI. */
    @Column(name = "approval_source", nullable = false, length = 20)
    private String approvalSource = "ADMIN";

    @Column(name = "meal_name", nullable = false, length = 150)
    private String mealName;

    @Column(name = "description")
    private String description;

    @Column(name = "main_image_url")
    private String mainImageUrl;

    @Column(name = "cooking_time_minutes")
    private Integer cookingTimeMinutes;

    @Column(name = "difficulty", length = 20)
    private String difficulty;

    @Column(name = "servings")
    private Integer servings;

    @Column(name = "calories_cached")
    private BigDecimal caloriesCached;

    @Column(name = "protein_grams_cached")
    private BigDecimal proteinGramsCached;

    @Column(name = "is_published", nullable = false)
    private Boolean isPublished;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @OneToMany(mappedBy = "meal", fetch = jakarta.persistence.FetchType.LAZY)
    private List<AiRecommendationItem> aiRecommendationItems = new ArrayList<>();

    public Meal() {
    }

    public Integer getMealId() {
        return mealId;
    }

    public MealCategory getCategory() {
        return category;
    }

    public void setCategory(MealCategory category) {
        this.category = category;
    }

    public User getCreatedByUser() {
        return createdByUser;
    }

    public void setCreatedByUser(User createdByUser) {
        this.createdByUser = createdByUser;
    }

    public Recipe getSourceRecipe() {
        return sourceRecipe;
    }

    public void setSourceRecipe(Recipe sourceRecipe) {
        this.sourceRecipe = sourceRecipe;
    }

    public String getSourceType() {
        return sourceType;
    }

    public void setSourceType(String sourceType) {
        this.sourceType = sourceType;
    }

    public String getApprovalSource() {
        return approvalSource;
    }

    public void setApprovalSource(String approvalSource) {
        this.approvalSource = approvalSource;
    }

    public String getMealName() {
        return mealName;
    }

    public void setMealName(String mealName) {
        this.mealName = mealName;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getMainImageUrl() {
        return mainImageUrl;
    }

    public void setMainImageUrl(String mainImageUrl) {
        this.mainImageUrl = mainImageUrl;
    }

    public Integer getCookingTimeMinutes() {
        return cookingTimeMinutes;
    }

    public void setCookingTimeMinutes(Integer cookingTimeMinutes) {
        this.cookingTimeMinutes = cookingTimeMinutes;
    }

    public String getDifficulty() {
        return difficulty;
    }

    public void setDifficulty(String difficulty) {
        this.difficulty = difficulty;
    }

    public Integer getServings() {
        return servings;
    }

    public void setServings(Integer servings) {
        this.servings = servings;
    }

    public BigDecimal getCaloriesCached() {
        return caloriesCached;
    }

    public void setCaloriesCached(BigDecimal caloriesCached) {
        this.caloriesCached = caloriesCached;
    }

    public BigDecimal getProteinGramsCached() {
        return proteinGramsCached;
    }

    public void setProteinGramsCached(BigDecimal proteinGramsCached) {
        this.proteinGramsCached = proteinGramsCached;
    }

    public Boolean getIsPublished() {
        return isPublished;
    }

    public void setIsPublished(Boolean published) {
        isPublished = published;
    }
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }

    public List<AiRecommendationItem> getAiRecommendationItems() {
        return aiRecommendationItems;
    }
}
