package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.MealCategory;

public interface MealCategoryRepository extends JpaRepository<MealCategory, Integer> {

    List<MealCategory> findAllByOrderBySortOrderAsc();
}
