package com.nhamhealth.nhamhealth_api.entity;

import java.math.BigDecimal;
import java.time.LocalDate;
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
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

@Entity
@Table(name = "daily_nutrition_source_logs", uniqueConstraints = @UniqueConstraint(
        name = "uk_nutrition_source_logs_source",
        columnNames = { "user_id", "source_type", "source_id" }))
public class DailyNutritionSourceLog {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "nutrition_source_log_id")
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "log_date", nullable = false)
    private LocalDate logDate;
    @Column(name = "source_type", nullable = false, length = 30)
    private String sourceType;
    @Column(name = "source_id", nullable = false, length = 100)
    private String sourceId;

    @Column(nullable = false) private BigDecimal calories = BigDecimal.ZERO;
    @Column(nullable = false) private BigDecimal protein = BigDecimal.ZERO;
    @Column(nullable = false) private BigDecimal carbs = BigDecimal.ZERO;
    @Column(nullable = false) private BigDecimal fat = BigDecimal.ZERO;
    @Column(nullable = false) private BigDecimal water = BigDecimal.ZERO;
    @Column(nullable = false) private BigDecimal fiber = BigDecimal.ZERO;
    @Column(nullable = false) private BigDecimal sugar = BigDecimal.ZERO;
    @Column(name = "created_at", nullable = false, updatable = false) private LocalDateTime createdAt;
    @Column(name = "updated_at", nullable = false) private LocalDateTime updatedAt;

    @PrePersist void create() { createdAt = updatedAt = LocalDateTime.now(); }
    @PreUpdate void update() { updatedAt = LocalDateTime.now(); }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }
    public LocalDate getLogDate() { return logDate; }
    public void setLogDate(LocalDate logDate) { this.logDate = logDate; }
    public String getSourceType() { return sourceType; }
    public void setSourceType(String sourceType) { this.sourceType = sourceType; }
    public String getSourceId() { return sourceId; }
    public void setSourceId(String sourceId) { this.sourceId = sourceId; }
    public BigDecimal getCalories() { return calories; }
    public void setCalories(BigDecimal value) { calories = value; }
    public BigDecimal getProtein() { return protein; }
    public void setProtein(BigDecimal value) { protein = value; }
    public BigDecimal getCarbs() { return carbs; }
    public void setCarbs(BigDecimal value) { carbs = value; }
    public BigDecimal getFat() { return fat; }
    public void setFat(BigDecimal value) { fat = value; }
    public BigDecimal getWater() { return water; }
    public void setWater(BigDecimal value) { water = value; }
    public BigDecimal getFiber() { return fiber; }
    public void setFiber(BigDecimal value) { fiber = value; }
    public BigDecimal getSugar() { return sugar; }
    public void setSugar(BigDecimal value) { sugar = value; }
}
