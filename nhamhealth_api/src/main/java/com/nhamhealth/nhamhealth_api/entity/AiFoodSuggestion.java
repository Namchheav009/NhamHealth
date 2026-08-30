package com.nhamhealth.nhamhealth_api.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "ai_food_suggestions")
public class AiFoodSuggestion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ai_food_suggestion_id")
    private Integer aiFoodSuggestionId;

    @ManyToOne(fetch = jakarta.persistence.FetchType.LAZY)
    @JoinColumn(name = "ai_food_analysis_id", nullable = false)
    private AiFoodAnalysis aiFoodAnalysis;

    @Column(name = "suggestion_type", nullable = false, length = 50)
    private String suggestionType;

    @Column(name = "title", nullable = false, length = 150)
    private String title;

    @Column(name = "description", nullable = false)
    private String description;

    @Column(name = "reason")
    private String reason;

    @Column(name = "priority", nullable = false)
    private Integer priority;

    public AiFoodSuggestion() {
    }

    public Integer getAiFoodSuggestionId() {
        return aiFoodSuggestionId;
    }

    public AiFoodAnalysis getAiFoodAnalysis() {
        return aiFoodAnalysis;
    }

    public void setAiFoodAnalysis(AiFoodAnalysis aiFoodAnalysis) {
        this.aiFoodAnalysis = aiFoodAnalysis;
    }

    public String getSuggestionType() {
        return suggestionType;
    }

    public void setSuggestionType(String suggestionType) {
        this.suggestionType = suggestionType;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getReason() {
        return reason;
    }

    public void setReason(String reason) {
        this.reason = reason;
    }

    public Integer getPriority() {
        return priority;
    }

    public void setPriority(Integer priority) {
        this.priority = priority;
    }
}
