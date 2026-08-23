package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;
import java.time.LocalDateTime;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.EntityGraph;

import com.nhamhealth.nhamhealth_api.entity.MealLog;

public interface MealLogRepository extends JpaRepository<MealLog, Integer> {

    @EntityGraph(attributePaths = {
            "user",
            "mealLogType",
            "meal",
            "servingSize"
    })
    List<MealLog> findAllByOrderByLoggedAtDesc();

    long countByLoggedAtGreaterThanEqualAndLoggedAtLessThan(LocalDateTime start, LocalDateTime end);
}
