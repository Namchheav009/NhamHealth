package com.nhamhealth.nhamhealth_api.repository.meal;

import java.util.List;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.WeeklyMealRecommendation;

public interface WeeklyMealRecommendationRepository
                extends JpaRepository<WeeklyMealRecommendation, Integer> {

        @EntityGraph(attributePaths = { "plannerMeal", "plannerMeal.category" })
        List<WeeklyMealRecommendation> findAllByOrderBySortOrderAscRecommendationIdAsc();

        @EntityGraph(attributePaths = { "plannerMeal", "plannerMeal.category" })
        List<WeeklyMealRecommendation> findAllByActiveTrueAndPlannerMealActiveTrueOrderBySortOrderAscRecommendationIdAsc();

        @EntityGraph(attributePaths = { "plannerMeal", "plannerMeal.category" })
        List<WeeklyMealRecommendation> findAllByActiveTrueAndPlannerMealActiveTrueAndDayOfWeekInOrderBySortOrderAscRecommendationIdAsc(
                        List<String> days);

        boolean existsByDayOfWeekAndMealSlotAndPlannerMealPlannerMealId(
                        String dayOfWeek, String mealSlot, Integer plannerMealId);

        boolean existsByActiveTrueAndDayOfWeekAndMealSlotAndPlannerMealPlannerMealIdAndPlannerMealActiveTrue(
                        String dayOfWeek, String mealSlot, Integer plannerMealId);

        boolean existsByActiveTrueAndDayOfWeekInAndMealSlotAndPlannerMealPlannerMealIdAndPlannerMealActiveTrue(
                        List<String> days, String mealSlot, Integer plannerMealId);

        boolean existsByDayOfWeekAndMealSlotAndPlannerMealPlannerMealIdAndRecommendationIdNot(
                        String dayOfWeek, String mealSlot, Integer plannerMealId, Integer recommendationId);

        long countByActiveTrue();
}
