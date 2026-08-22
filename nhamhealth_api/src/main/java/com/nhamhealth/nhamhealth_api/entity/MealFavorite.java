package com.nhamhealth.nhamhealth_api.entity;

import com.nhamhealth.nhamhealth_api.entity.User;

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
@Table(name = "meal_favorites", indexes = {
    @jakarta.persistence.Index(name = "idx_meal_favorites_meal_id", columnList = "meal_id"),
    @jakarta.persistence.Index(name = "idx_meal_favorites_user_id", columnList = "user_id")
})
public class MealFavorite {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "meal_favorite_id")
    private Integer mealFavoriteId;

    @ManyToOne(fetch = jakarta.persistence.FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = jakarta.persistence.FetchType.LAZY)
    @JoinColumn(name = "meal_id", nullable = false)
    private Meal meal;

    @Column(name = "saved_at", nullable = false)
    private LocalDateTime savedAt;

    public MealFavorite() {
    }

    public Integer getMealFavoriteId() {
        return mealFavoriteId;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public Meal getMeal() {
        return meal;
    }

    public void setMeal(Meal meal) {
        this.meal = meal;
    }

    public LocalDateTime getSavedAt() {
        return savedAt;
    }

    public void setSavedAt(LocalDateTime savedAt) {
        this.savedAt = savedAt;
    }
}
