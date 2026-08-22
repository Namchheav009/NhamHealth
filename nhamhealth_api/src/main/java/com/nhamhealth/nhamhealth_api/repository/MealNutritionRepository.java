package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.MealNutrition;

public interface MealNutritionRepository extends JpaRepository<MealNutrition, Integer> {
    List<MealNutrition> findByMealMealIdOrderByNutrientDisplayOrderAsc(Integer mealId);

    void deleteByNutrientNutrientId(Integer nutrientId);
}
