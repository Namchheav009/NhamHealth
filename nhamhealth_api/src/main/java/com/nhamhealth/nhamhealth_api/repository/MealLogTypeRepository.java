package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.MealLogType;

public interface MealLogTypeRepository extends JpaRepository<MealLogType, Integer> {
    List<MealLogType> findAllByOrderBySortOrderAsc();
}
