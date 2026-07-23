package com.nhamhealth.nhamhealth_api.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "nutrients")
public class Nutrient {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "nutrient_id")
    private Integer nutrientId;

    @Column(name = "nutrient_name", nullable = false, unique = true, length = 50)
    private String nutrientName;

    @Column(name = "unit", nullable = false, length = 20)
    private String unit;

    @Column(name = "display_order", nullable = false)
    private Integer displayOrder;

    @Column(name = "is_core", nullable = false)
    private Boolean isCore;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive;

    public Nutrient() {
    }

    public Integer getNutrientId() {
        return nutrientId;
    }

    public String getNutrientName() {
        return nutrientName;
    }

    public void setNutrientName(String nutrientName) {
        this.nutrientName = nutrientName;
    }

    public String getUnit() {
        return unit;
    }

    public void setUnit(String unit) {
        this.unit = unit;
    }

    public Integer getDisplayOrder() {
        return displayOrder;
    }

    public void setDisplayOrder(Integer displayOrder) {
        this.displayOrder = displayOrder;
    }

    public Boolean getIsCore() {
        return isCore;
    }

    public void setIsCore(Boolean core) {
        isCore = core;
    }

    public Boolean getIsActive() {
        return isActive;
    }

    public void setIsActive(Boolean active) {
        isActive = active;
    }
}
