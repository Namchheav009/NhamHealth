package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.RecipeStep;

public interface RecipeStepRepository extends JpaRepository<RecipeStep, Integer> {

    List<RecipeStep> findByMealMealIdOrderByStepNumberAsc(Integer mealId);

    List<RecipeStep> findByRecipeRecipeIdOrderByStepNumberAsc(Integer recipeId);

    void deleteByMealMealId(Integer mealId);

    void deleteByRecipeRecipeId(Integer recipeId);
}
