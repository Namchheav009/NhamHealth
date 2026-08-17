package com.nhamhealth.nhamhealth_api.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.AiFoodAnalysisNutrient;

public interface AiFoodAnalysisNutrientRepository
        extends JpaRepository<AiFoodAnalysisNutrient, Integer> {
}
