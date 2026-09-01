package com.nhamhealth.nhamhealth_api.repository.catalog;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.Ingredient;

public interface IngredientRepository extends JpaRepository<Ingredient, Integer> {

    List<Ingredient> findAllByOrderByIngredientNameAsc();

    List<Ingredient> findTop20ByIngredientNameContainingIgnoreCaseOrderByIngredientNameAsc(String ingredientName);

    Optional<Ingredient> findByIngredientNameIgnoreCase(String ingredientName);
}
