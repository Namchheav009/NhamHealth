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
<<<<<<< HEAD
@Table(name = "recipe_steps")
=======
@Table(name = "recipe_steps", indexes = {
    @jakarta.persistence.Index(name = "idx_recipe_steps_recipe_id", columnList = "recipe_id"),
    @jakarta.persistence.Index(name = "idx_recipe_steps_recipe_order", columnList = "recipe_id, step_number")
})
>>>>>>> de26f8c42978dce467e11832233dcabe163d6bc0
public class RecipeStep {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "step_id")
    private Integer stepId;

    @ManyToOne(fetch = jakarta.persistence.FetchType.LAZY)
<<<<<<< HEAD
    @JoinColumn(name = "meal_id", nullable = false)
    private Meal meal;

=======
    @JoinColumn(name = "meal_id")
    private Meal meal;

    /**
     * Community recipe owner. {@code meal} remains only for existing admin
     * meal instructions; a step belongs to exactly one of meal or recipe.
     */
    @ManyToOne(fetch = jakarta.persistence.FetchType.LAZY)
    @JoinColumn(name = "recipe_id")
    private Recipe recipe;

>>>>>>> de26f8c42978dce467e11832233dcabe163d6bc0
    @Column(name = "step_number", nullable = false)
    private Integer stepNumber;

    @Column(name = "step_title", length = 150)
    private String stepTitle;

    @Column(name = "instruction", nullable = false)
    private String instruction;

    @Column(name = "image_url")
    private String imageUrl;

    public RecipeStep() {
    }

    public Integer getStepId() {
        return stepId;
    }

    public Meal getMeal() {
        return meal;
    }

    public void setMeal(Meal meal) {
        this.meal = meal;
    }

<<<<<<< HEAD
=======
    public Recipe getRecipe() {
        return recipe;
    }

    public void setRecipe(Recipe recipe) {
        this.recipe = recipe;
    }

>>>>>>> de26f8c42978dce467e11832233dcabe163d6bc0
    public Integer getStepNumber() {
        return stepNumber;
    }

    public void setStepNumber(Integer stepNumber) {
        this.stepNumber = stepNumber;
    }

    public String getStepTitle() {
        return stepTitle;
    }

    public void setStepTitle(String stepTitle) {
        this.stepTitle = stepTitle;
    }

    public String getInstruction() {
        return instruction;
    }

    public void setInstruction(String instruction) {
        this.instruction = instruction;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }
}
