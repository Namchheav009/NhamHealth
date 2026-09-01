package com.nhamhealth.nhamhealth_api.repository.catalog;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.cache.annotation.Cacheable;

import com.nhamhealth.nhamhealth_api.entity.MealCategory;

public interface MealCategoryRepository extends JpaRepository<MealCategory, Integer> {

    @Cacheable("mealCategories")
    List<MealCategory> findAllByOrderBySortOrderAsc();

    @Cacheable("activeMealCategories")
    List<MealCategory> findAllByIsActiveTrueOrderBySortOrderAsc();

    Optional<MealCategory> findByCategoryNameIgnoreCase(String categoryName);
}
