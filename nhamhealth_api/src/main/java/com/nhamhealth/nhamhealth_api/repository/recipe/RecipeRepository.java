package com.nhamhealth.nhamhealth_api.repository.recipe;

import com.nhamhealth.nhamhealth_api.entity.Recipe;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface RecipeRepository extends JpaRepository<Recipe, Integer> {
    List<Recipe> findByStatusOrderByPublishedAtDesc(String status);
    List<Recipe> findByAuthorUserIdOrderByUpdatedAtDesc(Integer userId);
}
