package com.nhamhealth.nhamhealth_api.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

@Entity
@Table(name = "recipe_tags", uniqueConstraints =
        @UniqueConstraint(name = "uk_recipe_tags_recipe_tag", columnNames = {"user_meal_post_id", "tag_id"}), indexes = {
    @jakarta.persistence.Index(name = "idx_recipe_tags_tag_id", columnList = "tag_id")
})
public class RecipeTag {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @jakarta.persistence.Column(name = "recipe_tag_id")
    private Integer recipeTagId;

    @ManyToOne(fetch = jakarta.persistence.FetchType.LAZY)
    @JoinColumn(name = "user_meal_post_id", nullable = false)
    private Recipe recipe;

    @ManyToOne(fetch = jakarta.persistence.FetchType.LAZY)
    @JoinColumn(name = "tag_id", nullable = false)
    private TagType tag;

    public Integer getRecipeTagId() { return recipeTagId; }
    public Recipe getRecipe() { return recipe; }
    public void setRecipe(Recipe recipe) { this.recipe = recipe; }
    public TagType getTag() { return tag; }
    public void setTag(TagType tag) { this.tag = tag; }
}
