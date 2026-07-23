package com.nhamhealth.nhamhealth_api.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.math.BigDecimal;

@Entity
@Table(name = "serving_sizes")
public class ServingSize {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "serving_size_id")
    private Integer servingSizeId;

    @Column(name = "serving_size_name", nullable = false, unique = true, length = 50)
    private String servingSizeName;

    @Column(name = "multiplier", nullable = false)
    private BigDecimal multiplier;

    @Column(name = "description", length = 255)
    private String description;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive;

    public ServingSize() {
    }

    public Integer getServingSizeId() {
        return servingSizeId;
    }

    public String getServingSizeName() {
        return servingSizeName;
    }

    public void setServingSizeName(String servingSizeName) {
        this.servingSizeName = servingSizeName;
    }

    public BigDecimal getMultiplier() {
        return multiplier;
    }

    public void setMultiplier(BigDecimal multiplier) {
        this.multiplier = multiplier;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public Boolean getIsActive() {
        return isActive;
    }

    public void setIsActive(Boolean active) {
        isActive = active;
    }
}
