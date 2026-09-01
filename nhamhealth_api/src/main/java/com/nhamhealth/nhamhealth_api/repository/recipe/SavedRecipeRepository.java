package com.nhamhealth.nhamhealth_api.repository.recipe;

import com.nhamhealth.nhamhealth_api.entity.SavedRecipe;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SavedRecipeRepository extends JpaRepository<SavedRecipe, Integer> {
    Optional<SavedRecipe> findByUserUserIdAndRecipeRecipeId(Integer userId, Integer recipeId);

    List<SavedRecipe> findByUserUserIdOrderBySavedAtDesc(Integer userId);

    void deleteByRecipeRecipeId(Integer recipeId);
}
