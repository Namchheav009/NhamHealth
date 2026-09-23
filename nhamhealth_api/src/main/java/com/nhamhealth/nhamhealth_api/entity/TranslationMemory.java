package com.nhamhealth.nhamhealth_api.entity;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

@Entity
@Table(name = "translation_memory", uniqueConstraints = {
    @UniqueConstraint(name = "uk_translation_memory_hash_lang", columnNames = { "source_hash", "language_code" })
})
public class TranslationMemory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id")
    private Integer id;

    @Column(name = "source_text", nullable = false, length = 1000)
    private String sourceText;

    @Column(name = "translated_text", nullable = false, length = 2000)
    private String translatedText;

    @Column(name = "category", nullable = false, length = 50)
    private String category;

    @Column(name = "language_code", nullable = false, length = 2)
    private String languageCode = "km";

    @Column(name = "source_hash", nullable = false, length = 64)
    private String sourceHash;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    public TranslationMemory() {
    }

    public TranslationMemory(String sourceText, String translatedText, String category, String languageCode, String sourceHash) {
        this.sourceText = sourceText;
        this.translatedText = translatedText;
        this.category = category;
        this.languageCode = languageCode;
        this.sourceHash = sourceHash;
        this.createdAt = LocalDateTime.now();
    }

    public Integer getId() {
        return id;
    }

    public String getSourceText() {
        return sourceText;
    }

    public void setSourceText(String sourceText) {
        this.sourceText = sourceText;
    }

    public String getTranslatedText() {
        return translatedText;
    }

    public void setTranslatedText(String translatedText) {
        this.translatedText = translatedText;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public String getLanguageCode() {
        return languageCode;
    }

    public void setLanguageCode(String languageCode) {
        this.languageCode = languageCode;
    }

    public String getSourceHash() {
        return sourceHash;
    }

    public void setSourceHash(String sourceHash) {
        this.sourceHash = sourceHash;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
}

