package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import com.nhamhealth.nhamhealth_api.entity.FoodNutrition;

public interface FoodNutritionRepository extends JpaRepository<FoodNutrition, Integer> {
    Optional<FoodNutrition> findFirstByNameAndActiveTrue(String name);
    Optional<FoodNutrition> findFirstByNameIgnoreCaseAndActiveTrue(String name);

    @Query("select f from FoodNutrition f where f.active = true and "
            + "lower(coalesce(f.aliases, '')) like lower(concat('%', :term, '%'))")
    List<FoodNutrition> findAliasMatches(@Param("term") String term);

    List<FoodNutrition> findByNameContainingIgnoreCaseAndActiveTrueOrderByNameAsc(String name);
}
