package com.nhamhealth.nhamhealth_api.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.MealFavorite;

public interface MealFavoriteRepository extends JpaRepository<MealFavorite, Integer> {

    long countByMealMealId(Integer mealId);
}
