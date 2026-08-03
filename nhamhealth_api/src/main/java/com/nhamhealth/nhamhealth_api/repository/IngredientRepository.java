package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.Ingredient;

public interface IngredientRepository extends JpaRepository<Ingredient, Integer> {

    List<Ingredient> findAllByOrderByIngredientNameAsc();
}
