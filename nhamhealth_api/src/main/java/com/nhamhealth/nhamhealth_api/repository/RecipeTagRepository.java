package com.nhamhealth.nhamhealth_api.repository;

import com.nhamhealth.nhamhealth_api.entity.RecipeTag;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface RecipeTagRepository extends JpaRepository<RecipeTag, Integer> {
    List<RecipeTag> findByRecipeRecipeId(Integer recipeId);

    void deleteByRecipeRecipeId(Integer recipeId);
}
