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

    @Column(name = "model_name", length = 120)
    private String modelName;

    @Column(name = "prompt_version", length = 50)
    private String promptVersion;

    @Column(name = "database_matched")
    private Boolean databaseMatched;

    @Column(name = "user_confirmed")
    private Boolean userConfirmed;

    @Column(name = "corrected_food_name", length = 150)
    private String correctedFoodName;

    @Column(name = "corrected_serving_size", precision = 10, scale = 2)
    private BigDecimal correctedServingSize;

    @Column(name = "corrected_serving_unit", length = 40)
    private String correctedServingUnit;

    @Column(name = "feedback_at")
    private LocalDateTime feedbackAt;

    @Column(name = "nutrition_fallback_used")
    private Boolean nutritionFallbackUsed;

    @Column(name = "prompt_tokens")
    private Integer promptTokens;

    @Column(name = "completion_tokens")
    private Integer completionTokens;

    @Column(name = "latency_ms")
    private Long latencyMs;

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

    public String getModelName() { return modelName; }
    public void setModelName(String modelName) { this.modelName = modelName; }
    public String getPromptVersion() { return promptVersion; }
    public void setPromptVersion(String promptVersion) { this.promptVersion = promptVersion; }
    public Boolean getDatabaseMatched() { return databaseMatched; }
    public void setDatabaseMatched(Boolean databaseMatched) { this.databaseMatched = databaseMatched; }
    public Boolean getUserConfirmed() { return userConfirmed; }
    public void setUserConfirmed(Boolean userConfirmed) { this.userConfirmed = userConfirmed; }
    public String getCorrectedFoodName() { return correctedFoodName; }
    public void setCorrectedFoodName(String correctedFoodName) { this.correctedFoodName = correctedFoodName; }
    public BigDecimal getCorrectedServingSize() { return correctedServingSize; }
    public void setCorrectedServingSize(BigDecimal correctedServingSize) { this.correctedServingSize = correctedServingSize; }
    public String getCorrectedServingUnit() { return correctedServingUnit; }
    public void setCorrectedServingUnit(String correctedServingUnit) { this.correctedServingUnit = correctedServingUnit; }
    public LocalDateTime getFeedbackAt() { return feedbackAt; }
    public void setFeedbackAt(LocalDateTime feedbackAt) { this.feedbackAt = feedbackAt; }
    public Boolean getNutritionFallbackUsed() { return nutritionFallbackUsed; }
    public void setNutritionFallbackUsed(Boolean nutritionFallbackUsed) { this.nutritionFallbackUsed = nutritionFallbackUsed; }
    public Integer getPromptTokens() { return promptTokens; }
    public void setPromptTokens(Integer promptTokens) { this.promptTokens = promptTokens; }
    public Integer getCompletionTokens() { return completionTokens; }
    public void setCompletionTokens(Integer completionTokens) { this.completionTokens = completionTokens; }
    public Long getLatencyMs() { return latencyMs; }
    public void setLatencyMs(Long latencyMs) { this.latencyMs = latencyMs; }
}
