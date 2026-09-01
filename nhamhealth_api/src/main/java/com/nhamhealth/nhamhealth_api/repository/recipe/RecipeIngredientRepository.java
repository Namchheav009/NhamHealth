package com.nhamhealth.nhamhealth_api.repository.recipe;

import com.nhamhealth.nhamhealth_api.entity.RecipeIngredient;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface RecipeIngredientRepository extends JpaRepository<RecipeIngredient, Integer> {
    List<RecipeIngredient> findByRecipeRecipeIdOrderByDisplayOrderAsc(Integer recipeId);

    void deleteByRecipeRecipeId(Integer recipeId);
}
