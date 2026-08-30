package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.MealIngredient;

public interface MealIngredientRepository extends JpaRepository<MealIngredient, Integer> {

    List<MealIngredient> findByMealMealIdOrderByDisplayOrderAsc(Integer mealId);

    void deleteByMealMealId(Integer mealId);
}
