package com.nhamhealth.nhamhealth_api.repository.meal;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.MealPlan;

public interface MealPlanRepository extends JpaRepository<MealPlan, Integer> {
    @EntityGraph(attributePaths = { "plannerMeal" })
    List<MealPlan> findAllByUserUserIdAndPlanDateBetweenOrderByPlanDateAscMealTypeAsc(
            Integer userId, LocalDate start, LocalDate end);
    @EntityGraph(attributePaths = { "plannerMeal" })
    Optional<MealPlan> findByUserUserIdAndPlanDateAndMealType(Integer userId, LocalDate date, String mealType);
    @EntityGraph(attributePaths = { "plannerMeal" })
    Optional<MealPlan> findByMealPlanIdAndUserUserId(Integer id, Integer userId);
}
