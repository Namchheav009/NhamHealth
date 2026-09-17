package com.nhamhealth.nhamhealth_api.entity;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

@Entity
@Table(name = "meal_plans", uniqueConstraints = @UniqueConstraint(
        name = "uk_meal_plans_user_date_type", columnNames = { "user_id", "plan_date", "meal_type" }))
public class MealPlan {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "meal_plan_id") private Integer mealPlanId;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false) private User user;
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "meal_id") private Meal meal;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "planner_meal_id", nullable = false) private PlannerMeal plannerMeal;
    @Column(name = "plan_date", nullable = false) private LocalDate planDate;
    @Column(name = "meal_type", nullable = false, length = 20) private String mealType;
    @Column(name = "servings", nullable = false, precision = 6, scale = 2) private BigDecimal servings;
    @Column(name = "created_at", nullable = false, updatable = false) private LocalDateTime createdAt;
    @Column(name = "updated_at", nullable = false) private LocalDateTime updatedAt;

    @PrePersist void onCreate() { createdAt = updatedAt = LocalDateTime.now(); }
    @PreUpdate void onUpdate() { updatedAt = LocalDateTime.now(); }
    public Integer getMealPlanId() { return mealPlanId; }
    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }
    public Meal getMeal() { return meal; }
    public void setMeal(Meal meal) { this.meal = meal; }
    public PlannerMeal getPlannerMeal() { return plannerMeal; }
    public void setPlannerMeal(PlannerMeal plannerMeal) { this.plannerMeal = plannerMeal; }
    public LocalDate getPlanDate() { return planDate; }
    public void setPlanDate(LocalDate planDate) { this.planDate = planDate; }
    public String getMealType() { return mealType; }
    public void setMealType(String mealType) { this.mealType = mealType; }
    public BigDecimal getServings() { return servings; }
    public void setServings(BigDecimal servings) { this.servings = servings; }
}
