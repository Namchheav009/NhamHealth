package com.nhamhealth.nhamhealth_api.entity;

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

@Entity
@Table(name = "meal_plan_feedback")
public class MealPlanFeedback {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "meal_plan_feedback_id")
    private Integer id;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "meal_plan_id", nullable = false)
    private MealPlan mealPlan;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
    private Short rating;
    @Column(nullable = false, length = 20)
    private String outcome;
    @Column(name = "skip_reason", length = 80)
    private String skipReason;
    @Column(name = "hunger_before")
    private Short hungerBefore;
    @Column(name = "fullness_after")
    private Short fullnessAfter;
    @Column(name = "comment_text", length = 500)
    private String commentText;
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist void create() { createdAt = updatedAt = LocalDateTime.now(); }
    @PreUpdate void update() { updatedAt = LocalDateTime.now(); }

    public Integer getId() { return id; }
    public MealPlan getMealPlan() { return mealPlan; }
    public void setMealPlan(MealPlan value) { mealPlan = value; }
    public User getUser() { return user; }
    public void setUser(User value) { user = value; }
    public Short getRating() { return rating; }
    public void setRating(Short value) { rating = value; }
    public String getOutcome() { return outcome; }
    public void setOutcome(String value) { outcome = value; }
    public String getSkipReason() { return skipReason; }
    public void setSkipReason(String value) { skipReason = value; }
    public Short getHungerBefore() { return hungerBefore; }
    public void setHungerBefore(Short value) { hungerBefore = value; }
    public Short getFullnessAfter() { return fullnessAfter; }
    public void setFullnessAfter(Short value) { fullnessAfter = value; }
    public String getCommentText() { return commentText; }
    public void setCommentText(String value) { commentText = value; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
