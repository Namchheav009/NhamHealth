package com.nhamhealth.nhamhealth_api.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;

@Entity
@Table(name = "food_nutrition")
public class FoodNutrition {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(nullable = false, unique = true, length = 150)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String aliases;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal calories;
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal protein;
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal carbs;
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal fat;
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal sugar;
    @Column(precision = 10, scale = 2)
    private BigDecimal fiber;
    @Column(precision = 10, scale = 2)
    private BigDecimal sodium;

    @Column(name = "serving_size", nullable = false, precision = 10, scale = 2)
    private BigDecimal servingSize;
    @Column(name = "serving_unit", nullable = false, length = 40)
    private String servingUnit;
    @Column(name = "image_url")
    private String imageUrl;
    @Column(name = "is_active", nullable = false)
    private Boolean active = true;
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    void createTimestamps() { createdAt = updatedAt = LocalDateTime.now(); }
    @PreUpdate
    void updateTimestamp() { updatedAt = LocalDateTime.now(); }

    public Integer getId() { return id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getAliases() { return aliases; }
    public void setAliases(String aliases) { this.aliases = aliases; }
    public BigDecimal getCalories() { return calories; }
    public void setCalories(BigDecimal calories) { this.calories = calories; }
    public BigDecimal getProtein() { return protein; }
    public void setProtein(BigDecimal protein) { this.protein = protein; }
    public BigDecimal getCarbs() { return carbs; }
    public void setCarbs(BigDecimal carbs) { this.carbs = carbs; }
    public BigDecimal getFat() { return fat; }
    public void setFat(BigDecimal fat) { this.fat = fat; }
    public BigDecimal getSugar() { return sugar; }
    public void setSugar(BigDecimal sugar) { this.sugar = sugar; }
    public BigDecimal getFiber() { return fiber; }
    public void setFiber(BigDecimal fiber) { this.fiber = fiber; }
    public BigDecimal getSodium() { return sodium; }
    public void setSodium(BigDecimal sodium) { this.sodium = sodium; }
    public BigDecimal getServingSize() { return servingSize; }
    public void setServingSize(BigDecimal servingSize) { this.servingSize = servingSize; }
    public String getServingUnit() { return servingUnit; }
    public void setServingUnit(String servingUnit) { this.servingUnit = servingUnit; }
    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }
    public Boolean getActive() { return active; }
    public void setActive(Boolean active) { this.active = active; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
