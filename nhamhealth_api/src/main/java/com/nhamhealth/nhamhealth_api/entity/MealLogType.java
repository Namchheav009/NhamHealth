package com.nhamhealth.nhamhealth_api.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "meal_log_types")
public class MealLogType {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "meal_log_type_id")
    private Integer mealLogTypeId;

    @Column(name = "meal_log_type_name", nullable = false, unique = true, length = 50)
    private String mealLogTypeName;

    @Column(name = "sort_order", nullable = false)
    private Integer sortOrder;

    public MealLogType() {
    }

    public Integer getMealLogTypeId() {
        return mealLogTypeId;
    }

    public String getMealLogTypeName() {
        return mealLogTypeName;
    }

    public void setMealLogTypeName(String mealLogTypeName) {
        this.mealLogTypeName = mealLogTypeName;
    }

    public Integer getSortOrder() {
        return sortOrder;
    }

    public void setSortOrder(Integer sortOrder) {
        this.sortOrder = sortOrder;
    }
}
