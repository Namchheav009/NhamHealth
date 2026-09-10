package com.nhamhealth.nhamhealth_api.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "meal_translations", uniqueConstraints = @UniqueConstraint(name = "uk_meal_translations_language", columnNames = {"meal_id", "language_code"}))
public class MealTranslation {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Integer id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "meal_id", nullable = false) private Meal meal;
    @Column(name = "language_code", nullable = false, length = 2) private String languageCode;
    @Column(name = "meal_name", nullable = false, length = 150) private String mealName;
    @Column(length = 1000) private String description;
    public Integer getId() { return id; }
    public Meal getMeal() { return meal; } public void setMeal(Meal meal) { this.meal = meal; }
    public String getLanguageCode() { return languageCode; } public void setLanguageCode(String value) { languageCode = value; }
    public String getMealName() { return mealName; } public void setMealName(String value) { mealName = value; }
    public String getDescription() { return description; } public void setDescription(String value) { description = value; }
}
