package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.Nutrient;

public interface NutrientRepository extends JpaRepository<Nutrient, Integer> {

    List<Nutrient> findAllByOrderByDisplayOrderAsc();

    boolean existsByNutrientNameIgnoreCase(String nutrientName);

    boolean existsByNutrientNameIgnoreCaseAndNutrientIdNot(String nutrientName, Integer nutrientId);
}
