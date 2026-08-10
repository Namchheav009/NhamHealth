package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.UserNutrientGoal;

public interface UserNutrientGoalRepository extends JpaRepository<UserNutrientGoal, Integer> {

    List<UserNutrientGoal> findByIsActiveTrueOrderByEffectiveFromDesc();

    List<UserNutrientGoal> findAllByOrderByEffectiveFromDesc();
}
