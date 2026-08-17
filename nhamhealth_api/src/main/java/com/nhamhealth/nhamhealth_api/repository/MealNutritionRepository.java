package com.nhamhealth.nhamhealth_api.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.MealNutrition;

public interface MealNutritionRepository extends JpaRepository<MealNutrition, Integer> {
    void deleteByNutrientNutrientId(Integer nutrientId);
}
