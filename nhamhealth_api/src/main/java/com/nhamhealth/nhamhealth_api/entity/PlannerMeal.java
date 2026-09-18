package com.nhamhealth.nhamhealth_api.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;
import java.util.stream.Collectors;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.JoinTable;
import jakarta.persistence.ManyToMany;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;

@Entity
@Table(name = "planner_meals")
public class PlannerMeal {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "planner_meal_id")
    private Integer plannerMealId;
    @Column(name = "legacy_meal_id")
    private Integer legacyMealId;
    @Column(name = "name_en", nullable = false, length = 150)
    private String nameEn;
    @Column(name = "name_km", length = 150)
    private String nameKm;
    @ManyToOne(fetch = FetchType.EAGER, optional = false)
    @JoinColumn(name = "category_id", nullable = false)
    private MealCategory category;

    @ManyToMany(fetch = FetchType.EAGER)
    @JoinTable(name = "planner_meal_categories", joinColumns = @JoinColumn(name = "planner_meal_id"), inverseJoinColumns = @JoinColumn(name = "category_id"))
    private Set<MealCategory> categories = new HashSet<>();
    @Column(name = "category_en", nullable = false, length = 80)
    private String categoryEn;
    @Column(name = "category_km", length = 80)
    private String categoryKm;
    @Column(name = "description_en", columnDefinition = "text")
    private String descriptionEn;
    @Column(name = "description_km", columnDefinition = "text")
    private String descriptionKm;
    @Column(name = "image_url", length = 500)
    private String imageUrl;
    @Column(name = "calories", nullable = false)
    private BigDecimal calories = BigDecimal.ZERO;
    @Column(name = "protein_grams", nullable = false)
    private BigDecimal proteinGrams = BigDecimal.ZERO;
    @Column(name = "carbs_grams", nullable = false)
    private BigDecimal carbsGrams = BigDecimal.ZERO;
    @Column(name = "fat_grams", nullable = false)
    private BigDecimal fatGrams = BigDecimal.ZERO;
    @Column(name = "cooking_time_minutes")
    private Integer cookingTimeMinutes;
    @Column(name = "ingredients_text", columnDefinition = "text")
    private String ingredientsText;
    @Column(name = "ingredients_text_km", columnDefinition = "text")
    private String ingredientsTextKm;
    @Column(name = "instructions_text", columnDefinition = "text")
    private String instructionsText;
    @Column(name = "instructions_text_km", columnDefinition = "text")
    private String instructionsTextKm;
    @Column(name = "tags_text", length = 500)
    private String tagsText;
    @Column(name = "tags_text_km", length = 500)
    private String tagsTextKm;
    @Column(name = "is_active", nullable = false)
    private Boolean active = true;
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    void create() {
        createdAt = updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    void update() {
        updatedAt = LocalDateTime.now();
    }

    public Integer getPlannerMealId() {
        return plannerMealId;
    }

    public void setPlannerMealId(Integer v) {
        plannerMealId = v;
    }

    public Integer getLegacyMealId() {
        return legacyMealId;
    }

    public String getNameEn() {
        return nameEn;
    }

    public void setNameEn(String v) {
        nameEn = v;
    }

    public String getNameKm() {
        return nameKm;
    }

    public void setNameKm(String v) {
        nameKm = v;
    }

    public String getCategoryEn() {
        return categoryEn;
    }

    public void setCategoryEn(String v) {
        categoryEn = v;
    }

    public String getCategoryKm() {
        return categoryKm;
    }

    public void setCategoryKm(String v) {
        categoryKm = v;
    }

    public MealCategory getCategory() {
        return category;
    }

    public void setCategory(MealCategory v) {
        category = v;
    }

    public Set<MealCategory> getCategories() {
        if (categories == null) {
            return Collections.emptySet();
        }
        try {
            categories.size();
            return categories;
        } catch (Exception ex) {
            return Collections.emptySet();
        }
    }

    public void setCategories(Set<MealCategory> v) {
        this.categories = v != null ? v : new HashSet<>();
    }

    public Set<Integer> getCategoryIds() {
        Set<Integer> ids = new HashSet<>();
        try {
            if (category != null && category.getCategoryId() != null) {
                ids.add(category.getCategoryId());
            }
        } catch (Exception ignored) {
        }
        try {
            if (categories != null) {
                for (MealCategory cat : categories) {
                    if (cat != null && cat.getCategoryId() != null)
                        ids.add(cat.getCategoryId());
                }
            }
        } catch (Exception ignored) {
        }
        return ids;
    }

    public String getCategoryIdsString() {
        try {
            return getCategoryIds().stream().sorted().map(String::valueOf).collect(Collectors.joining(","));
        } catch (Exception ignored) {
            return "";
        }
    }

    public String getDescriptionEn() {
        return descriptionEn;
    }

    public void setDescriptionEn(String v) {
        descriptionEn = v;
    }

    public String getDescriptionKm() {
        return descriptionKm;
    }

    public void setDescriptionKm(String v) {
        descriptionKm = v;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String v) {
        imageUrl = v;
    }

    public BigDecimal getCalories() {
        return calories;
    }

    public void setCalories(BigDecimal v) {
        calories = v;
    }

    public BigDecimal getProteinGrams() {
        return proteinGrams;
    }

    public void setProteinGrams(BigDecimal v) {
        proteinGrams = v;
    }

    public BigDecimal getCarbsGrams() {
        return carbsGrams;
    }

    public void setCarbsGrams(BigDecimal v) {
        carbsGrams = v;
    }

    public BigDecimal getFatGrams() {
        return fatGrams;
    }

    public void setFatGrams(BigDecimal v) {
        fatGrams = v;
    }

    public Integer getCookingTimeMinutes() {
        return cookingTimeMinutes;
    }

    public void setCookingTimeMinutes(Integer v) {
        cookingTimeMinutes = v;
    }

    public String getIngredientsText() {
        return ingredientsText;
    }

    public void setIngredientsText(String v) {
        ingredientsText = v;
    }

    public String getIngredientsTextKm() {
        return ingredientsTextKm;
    }

    public void setIngredientsTextKm(String v) {
        ingredientsTextKm = v;
    }

    public String getInstructionsText() {
        return instructionsText;
    }

    public void setInstructionsText(String v) {
        instructionsText = v;
    }

    public String getInstructionsTextKm() {
        return instructionsTextKm;
    }

    public void setInstructionsTextKm(String v) {
        instructionsTextKm = v;
    }

    public String getTagsText() {
        return tagsText;
    }

    public void setTagsText(String v) {
        tagsText = v;
    }

    public String getTagsTextKm() {
        return tagsTextKm;
    }

    public void setTagsTextKm(String v) {
        tagsTextKm = v;
    }

    public Boolean getActive() {
        return active;
    }

    public void setActive(Boolean v) {
        active = v;
    }

    public String name(String lang) {
        return "km".equalsIgnoreCase(lang) && nameKm != null && !nameKm.isBlank() ? nameKm : nameEn;
    }

    public String category(String lang) {
        return "km".equalsIgnoreCase(lang) && categoryKm != null && !categoryKm.isBlank() ? categoryKm : categoryEn;
    }

    public String description(String lang) {
        return "km".equalsIgnoreCase(lang) && descriptionKm != null && !descriptionKm.isBlank() ? descriptionKm
                : descriptionEn;
    }

    public String instructions(String lang) {
        return "km".equalsIgnoreCase(lang) && instructionsTextKm != null && !instructionsTextKm.isBlank()
                ? instructionsTextKm
                : instructionsText;
    }

    public String tags(String lang) {
        return "km".equalsIgnoreCase(lang) && tagsTextKm != null && !tagsTextKm.isBlank() ? tagsTextKm : tagsText;
    }
}
