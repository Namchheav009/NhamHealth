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
import java.time.LocalDateTime;

@Entity
@Table(name = "ai_food_analyses")
public class AiFoodAnalysis {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ai_food_analysis_id")
    private Integer aiFoodAnalysisId;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "input_text", nullable = false)
    private String inputText;

    @Column(name = "detected_food_name", length = 150)
    private String detectedFoodName;

    @Column(name = "analysis_text", length = 1000)
    private String analysisText;

    @Column(name = "detected_serving_text", length = 100)
    private String detectedServingText;

    @Column(name = "confidence_score")
    private BigDecimal confidenceScore;

    @Column(name = "status", nullable = false, length = 20)
    private String status;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    public AiFoodAnalysis() {
    }

    public Integer getAiFoodAnalysisId() {
        return aiFoodAnalysisId;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public String getInputText() {
        return inputText;
    }

    public void setInputText(String inputText) {
        this.inputText = inputText;
    }

    public String getDetectedFoodName() {
        return detectedFoodName;
    }

    public void setDetectedFoodName(String detectedFoodName) {
        this.detectedFoodName = detectedFoodName;
    }

    public String getAnalysisText() {
        return analysisText;
    }

    public void setAnalysisText(String analysisText) {
        this.analysisText = analysisText;
    }

    public String getDetectedServingText() {
        return detectedServingText;
    }

    public void setDetectedServingText(String detectedServingText) {
        this.detectedServingText = detectedServingText;
    }

    public BigDecimal getConfidenceScore() {
        return confidenceScore;
    }

    public void setConfidenceScore(BigDecimal confidenceScore) {
        this.confidenceScore = confidenceScore;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
