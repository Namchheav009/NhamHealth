package com.nhamhealth.nhamhealth_api.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "recipe_step_translations", uniqueConstraints = @UniqueConstraint(name = "uk_recipe_step_translations_language", columnNames = {"recipe_step_id", "language_code"}))
public class RecipeStepTranslation {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Integer id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "recipe_step_id", nullable = false) private RecipeStep recipeStep;
    @Column(name = "language_code", nullable = false, length = 2) private String languageCode;
    @Column(nullable = false, length = 4000) private String instruction;
    public Integer getId() { return id; }
    public RecipeStep getRecipeStep() { return recipeStep; } public void setRecipeStep(RecipeStep value) { recipeStep = value; }
    public String getLanguageCode() { return languageCode; } public void setLanguageCode(String value) { languageCode = value; }
    public String getInstruction() { return instruction; } public void setInstruction(String value) { instruction = value; }
}
