package com.nhamhealth.nhamhealth_api.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "meal_ingredient_translations", uniqueConstraints = @UniqueConstraint(name = "uk_meal_ingredient_translations_language", columnNames = {"meal_ingredient_id", "language_code"}))
public class MealIngredientTranslation {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Integer id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "meal_ingredient_id", nullable = false) private MealIngredient mealIngredient;
    @Column(name = "language_code", nullable = false, length = 2) private String languageCode;
    @Column(name = "preparation_note", length = 150) private String preparationNote;
    public Integer getId() { return id; }
    public MealIngredient getMealIngredient() { return mealIngredient; } public void setMealIngredient(MealIngredient value) { mealIngredient = value; }
    public String getLanguageCode() { return languageCode; } public void setLanguageCode(String value) { languageCode = value; }
    public String getPreparationNote() { return preparationNote; } public void setPreparationNote(String value) { preparationNote = value; }
}
