package com.nhamhealth.nhamhealth_api.repository.catalog;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.cache.annotation.Cacheable;

import com.nhamhealth.nhamhealth_api.entity.Nutrient;

public interface NutrientRepository extends JpaRepository<Nutrient, Integer> {

    @Cacheable("nutrients")
    List<Nutrient> findAllByOrderByDisplayOrderAsc();

    boolean existsByNutrientNameIgnoreCase(String nutrientName);

    boolean existsByNutrientNameIgnoreCaseAndNutrientIdNot(String nutrientName, Integer nutrientId);

    Optional<Nutrient> findByNutrientNameIgnoreCase(String nutrientName);
}
