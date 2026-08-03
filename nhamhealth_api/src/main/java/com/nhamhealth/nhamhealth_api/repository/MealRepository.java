package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.Meal;

public interface MealRepository extends JpaRepository<Meal, Integer> {

    List<Meal> findAllByOrderByUpdatedAtDesc();

    long countByCategoryCategoryId(Integer categoryId);
}
