package com.nhamhealth.nhamhealth_api.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

import java.math.BigDecimal;

@Entity
@Table(name = "ai_food_analysis_nutrients")
public class AiFoodAnalysisNutrient {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "analysis_nutrient_id")
    private Integer analysisNutrientId;

    @ManyToOne
    @JoinColumn(name = "ai_food_analysis_id", nullable = false)
    private AiFoodAnalysis aiFoodAnalysis;

    @ManyToOne
    @JoinColumn(name = "nutrient_id", nullable = false)
    private Nutrient nutrient;

    @Column(name = "estimated_amount", nullable = false)
    private BigDecimal estimatedAmount;

    public AiFoodAnalysisNutrient() {
    }

    public Integer getAnalysisNutrientId() {
        return analysisNutrientId;
    }

    public AiFoodAnalysis getAiFoodAnalysis() {
        return aiFoodAnalysis;
    }

    public void setAiFoodAnalysis(AiFoodAnalysis aiFoodAnalysis) {
        this.aiFoodAnalysis = aiFoodAnalysis;
    }

    public Nutrient getNutrient() {
        return nutrient;
    }

    public void setNutrient(Nutrient nutrient) {
        this.nutrient = nutrient;
    }

    public BigDecimal getEstimatedAmount() {
        return estimatedAmount;
    }

    public void setEstimatedAmount(BigDecimal estimatedAmount) {
        this.estimatedAmount = estimatedAmount;
    }
}
