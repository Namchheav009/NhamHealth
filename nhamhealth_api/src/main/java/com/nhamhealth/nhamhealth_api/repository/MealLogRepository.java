package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.MealLog;

public interface MealLogRepository extends JpaRepository<MealLog, Integer> {

    List<MealLog> findAllByOrderByLoggedAtDesc();
}
