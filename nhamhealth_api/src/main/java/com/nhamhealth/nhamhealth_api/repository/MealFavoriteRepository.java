package com.nhamhealth.nhamhealth_api.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.MealFavorite;

public interface MealFavoriteRepository extends JpaRepository<MealFavorite, Integer> {

    long countByMealMealId(Integer mealId);

    boolean existsByUserUserIdAndMealMealId(Integer userId, Integer mealId);

    boolean existsByUserUserIdAndMealMealIdAndMealFavoriteIdNot(Integer userId, Integer mealId, Integer favoriteId);

    java.util.List<MealFavorite> findAllByOrderBySavedAtDesc();

    java.util.List<MealFavorite> findAllByUserUserIdOrderBySavedAtDesc(Integer userId);

    java.util.Optional<MealFavorite> findByUserUserIdAndMealMealId(Integer userId, Integer mealId);
}
