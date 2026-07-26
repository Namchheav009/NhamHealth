package com.nhamhealth.nhamhealth_api.entity;

import com.nhamhealth.nhamhealth_api.user.entity.User;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "meal_logs")
public class MealLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "meal_log_id")
    private Integer mealLogId;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne
    @JoinColumn(name = "meal_log_type_id", nullable = false)
    private MealLogType mealLogType;

    @ManyToOne
    @JoinColumn(name = "meal_id")
    private Meal meal;

    @ManyToOne
    @JoinColumn(name = "serving_size_id")
    private ServingSize servingSize;

    @ManyToOne
    @JoinColumn(name = "ai_food_analysis_id")
    private AiFoodAnalysis aiFoodAnalysis;

    @Column(name = "custom_food_name", length = 150)
    private String customFoodName;

    @Column(name = "quantity", nullable = false)
    private BigDecimal quantity;

    @Column(name = "entry_method", nullable = false, length = 20)
    private String entryMethod;

    @Column(name = "logged_at", nullable = false)
    private LocalDateTime loggedAt;

    @Column(name = "notes")
    private String notes;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    public MealLog() {
    }

    public Integer getMealLogId() {
        return mealLogId;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public MealLogType getMealLogType() {
        return mealLogType;
    }

    public void setMealLogType(MealLogType mealLogType) {
        this.mealLogType = mealLogType;
    }

    public Meal getMeal() {
        return meal;
    }

    public void setMeal(Meal meal) {
        this.meal = meal;
    }

    public ServingSize getServingSize() {
        return servingSize;
    }

    public void setServingSize(ServingSize servingSize) {
        this.servingSize = servingSize;
    }

    public AiFoodAnalysis getAiFoodAnalysis() {
        return aiFoodAnalysis;
    }

    public void setAiFoodAnalysis(AiFoodAnalysis aiFoodAnalysis) {
        this.aiFoodAnalysis = aiFoodAnalysis;
    }

    public String getCustomFoodName() {
        return customFoodName;
    }

    public void setCustomFoodName(String customFoodName) {
        this.customFoodName = customFoodName;
    }

    public BigDecimal getQuantity() {
        return quantity;
    }

    public void setQuantity(BigDecimal quantity) {
        this.quantity = quantity;
    }

    public String getEntryMethod() {
        return entryMethod;
    }

    public void setEntryMethod(String entryMethod) {
        this.entryMethod = entryMethod;
    }

    public LocalDateTime getLoggedAt() {
        return loggedAt;
    }

    public void setLoggedAt(LocalDateTime loggedAt) {
        this.loggedAt = loggedAt;
    }

    public String getNotes() {
        return notes;
    }

    public void setNotes(String notes) {
        this.notes = notes;
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
}
