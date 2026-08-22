package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.nhamhealth.nhamhealth_api.entity.MealFavorite;

public interface MealFavoriteRepository extends JpaRepository<MealFavorite, Integer> {

    @Query(value = "SELECT COUNT(*) FROM meal_favorites", nativeQuery = true)
    long countAllFavorites();

    @Modifying
    @Query("delete from MealFavorite favorite where favorite.user.userId = :userId")
    int deleteAllByUserId(@Param("userId") Integer userId);

        @Modifying
        @Query(value = """
            INSERT INTO meal_favorites (user_id, meal_id, saved_at)
            SELECT :userId, meal.meal_id, CURRENT_TIMESTAMP
            FROM meals meal
            WHERE meal.meal_id IN (:mealIds)
              AND meal.is_published = true
            ON CONFLICT DO NOTHING
            """, nativeQuery = true)
        int addAllPublishedByUserId(
            @Param("userId") Integer userId,
            @Param("mealIds") List<Integer> mealIds);

    long countByMealMealId(Integer mealId);

    boolean existsByUserUserIdAndMealMealId(Integer userId, Integer mealId);

    boolean existsByUserUserIdAndMealMealIdAndMealFavoriteIdNot(Integer userId, Integer mealId, Integer favoriteId);

    java.util.List<MealFavorite> findAllByOrderBySavedAtDesc();

    @EntityGraph(attributePaths = { "meal", "meal.category" })
    java.util.List<MealFavorite> findAllByUserUserIdOrderBySavedAtDesc(Integer userId);

    java.util.Optional<MealFavorite> findByUserUserIdAndMealMealId(Integer userId, Integer mealId);
}
