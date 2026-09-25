package com.nhamhealth.nhamhealth_api.entity;

import java.math.BigDecimal;
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
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

@Entity
@Table(name = "planner_meal_ingredients", uniqueConstraints = {
        @UniqueConstraint(name = "uk_planner_meal_ingredient", columnNames = { "planner_meal_id", "ingredient_id" }),
        @UniqueConstraint(name = "uk_planner_meal_ingredient_order", columnNames = { "planner_meal_id", "display_order" })
})
public class PlannerMealIngredient {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "planner_meal_ingredient_id")
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "planner_meal_id", nullable = false)
    private PlannerMeal plannerMeal;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "ingredient_id", nullable = false)
    private Ingredient ingredient;

    @Column(name = "quantity", precision = 10, scale = 2)
    private BigDecimal quantity;
    @Column(name = "unit", length = 30)
    private String unit;
    @Column(name = "preparation_note", length = 150)
    private String preparationNote;
    @Column(name = "display_order", nullable = false)
    private Integer displayOrder;
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    void create() { createdAt = LocalDateTime.now(); }
}
