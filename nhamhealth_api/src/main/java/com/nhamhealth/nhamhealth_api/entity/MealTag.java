package com.nhamhealth.nhamhealth_api.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "meal_tags", indexes = {
    @jakarta.persistence.Index(name = "idx_meal_tags_meal_id", columnList = "meal_id"),
    @jakarta.persistence.Index(name = "idx_meal_tags_tag_id", columnList = "tag_id")
})
public class MealTag {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @jakarta.persistence.Column(name = "meal_tag_id")
    private Integer mealTagId;

    @ManyToOne(fetch = jakarta.persistence.FetchType.LAZY)
    @JoinColumn(name = "meal_id", nullable = false)
    private Meal meal;

    @ManyToOne(fetch = jakarta.persistence.FetchType.LAZY)
    @JoinColumn(name = "tag_id", nullable = false)
    private TagType tag;

    public MealTag() {
    }

    public Integer getMealTagId() {
        return mealTagId;
    }

    public Meal getMeal() {
        return meal;
    }

    public void setMeal(Meal meal) {
        this.meal = meal;
    }

    public TagType getTag() {
        return tag;
    }

    public void setTag(TagType tag) {
        this.tag = tag;
    }
}
