package com.nhamhealth.nhamhealth_api.repository.meal;

import java.util.List;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.PlannerMeal;

public interface PlannerMealRepository extends JpaRepository<PlannerMeal, Integer> {
    // Fetching every collection in one query produces a Cartesian product that can
    // become large enough to exhaust or drop remote database connections. The
    // collections are batch-loaded on demand within the calling transaction.
    @EntityGraph(attributePaths = "category")
    List<PlannerMeal> findAllByOrderByNameEnAsc();
}
