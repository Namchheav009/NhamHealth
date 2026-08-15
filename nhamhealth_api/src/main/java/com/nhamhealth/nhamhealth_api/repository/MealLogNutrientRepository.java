package com.nhamhealth.nhamhealth_api.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.MealLogNutrient;

public interface MealLogNutrientRepository extends JpaRepository<MealLogNutrient, Integer> {
    void deleteByMealLogMealLogId(Integer mealLogId);
}
