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
@Table(name = "daily_nutrient_totals")
public class DailyNutrientTotal {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "daily_nutrient_total_id")
    private Integer dailyNutrientTotalId;

    @ManyToOne(fetch = jakarta.persistence.FetchType.LAZY)
    @JoinColumn(name = "daily_summary_id", nullable = false)
    private DailyWellnessSummary dailyWellnessSummary;

    @ManyToOne(fetch = jakarta.persistence.FetchType.LAZY)
    @JoinColumn(name = "nutrient_id", nullable = false)
    private Nutrient nutrient;

    @Column(name = "consumed_amount", nullable = false)
    private BigDecimal consumedAmount;

    @Column(name = "goal_amount", nullable = false)
    private BigDecimal goalAmount;

    @Column(name = "percentage")
    private BigDecimal percentage;

    public DailyNutrientTotal() {
    }

    public Integer getDailyNutrientTotalId() {
        return dailyNutrientTotalId;
    }

    public DailyWellnessSummary getDailyWellnessSummary() {
        return dailyWellnessSummary;
    }

    public void setDailyWellnessSummary(DailyWellnessSummary dailyWellnessSummary) {
        this.dailyWellnessSummary = dailyWellnessSummary;
    }

    public Nutrient getNutrient() {
        return nutrient;
    }

    public void setNutrient(Nutrient nutrient) {
        this.nutrient = nutrient;
    }

    public BigDecimal getConsumedAmount() {
        return consumedAmount;
    }

    public void setConsumedAmount(BigDecimal consumedAmount) {
        this.consumedAmount = consumedAmount;
    }

    public BigDecimal getGoalAmount() {
        return goalAmount;
    }

    public void setGoalAmount(BigDecimal goalAmount) {
        this.goalAmount = goalAmount;
    }

    public BigDecimal getPercentage() {
        return percentage;
    }

    public void setPercentage(BigDecimal percentage) {
        this.percentage = percentage;
    }
}
