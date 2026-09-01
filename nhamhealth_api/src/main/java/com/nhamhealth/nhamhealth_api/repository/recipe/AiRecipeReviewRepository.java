package com.nhamhealth.nhamhealth_api.repository.recipe;

import com.nhamhealth.nhamhealth_api.entity.AiRecipeReview;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AiRecipeReviewRepository extends JpaRepository<AiRecipeReview, Integer> {
    List<AiRecipeReview> findByRecipeRecipeIdOrderByCreatedAtDesc(Integer recipeId);

    void deleteByRecipeRecipeId(Integer recipeId);
}
