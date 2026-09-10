package com.nhamhealth.nhamhealth_api.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "ingredient_translations", uniqueConstraints = @UniqueConstraint(name = "uk_ingredient_translations_language", columnNames = {"ingredient_id", "language_code"}))
public class IngredientTranslation {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Integer id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "ingredient_id", nullable = false) private Ingredient ingredient;
    @Column(name = "language_code", nullable = false, length = 2) private String languageCode;
    @Column(nullable = false, length = 100) private String name;
    @Column(length = 1000) private String description;
    public Integer getId() { return id; }
    public Ingredient getIngredient() { return ingredient; } public void setIngredient(Ingredient value) { ingredient = value; }
    public String getLanguageCode() { return languageCode; } public void setLanguageCode(String value) { languageCode = value; }
    public String getName() { return name; } public void setName(String value) { name = value; }
    public String getDescription() { return description; } public void setDescription(String value) { description = value; }
}
