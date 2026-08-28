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
import jakarta.persistence.UniqueConstraint;

import java.time.LocalDateTime;

@Entity
@Table(name = "saved_recipes", uniqueConstraints =
        @UniqueConstraint(name = "uk_saved_recipes_user_recipe", columnNames = {"user_id", "recipe_id"}), indexes = {
    @jakarta.persistence.Index(name = "idx_saved_recipes_recipe_id", columnList = "recipe_id")
})
public class SavedRecipe {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "saved_recipe_id")
    private Integer savedRecipeId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recipe_id", nullable = false)
    private Recipe recipe;

    @Column(name = "saved_at", nullable = false, updatable = false)
    private LocalDateTime savedAt;

    public Integer getSavedRecipeId() { return savedRecipeId; }
    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }
    public Recipe getRecipe() { return recipe; }
    public void setRecipe(Recipe recipe) { this.recipe = recipe; }
    public LocalDateTime getSavedAt() { return savedAt; }
    public void setSavedAt(LocalDateTime savedAt) { this.savedAt = savedAt; }
}
