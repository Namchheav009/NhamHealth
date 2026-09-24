package com.nhamhealth.nhamhealth_api.repository.meal;

import java.util.List;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.PlannerMeal;

public interface PlannerMealRepository extends JpaRepository<PlannerMeal, Integer> {
    @EntityGraph(attributePaths = { "category", "categories", "weightGoals" })
    List<PlannerMeal> findAllByOrderByNameEnAsc();
}
