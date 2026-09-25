package com.nhamhealth.nhamhealth_api.repository.meal;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.MealPlanFeedback;

public interface MealPlanFeedbackRepository extends JpaRepository<MealPlanFeedback, Integer> {
    Optional<MealPlanFeedback> findByMealPlanMealPlanIdAndUserUserId(Integer mealPlanId, Integer userId);
}
