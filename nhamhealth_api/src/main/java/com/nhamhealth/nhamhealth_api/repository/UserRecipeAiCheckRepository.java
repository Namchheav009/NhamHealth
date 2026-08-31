package com.nhamhealth.nhamhealth_api.repository;

import com.nhamhealth.nhamhealth_api.entity.UserRecipeAiCheck;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface UserRecipeAiCheckRepository extends JpaRepository<UserRecipeAiCheck, Integer> {
    List<UserRecipeAiCheck> findByRecipeRecipeIdOrderByCreatedAtDesc(Integer recipeId);

    void deleteByRecipeRecipeId(Integer recipeId);
}
