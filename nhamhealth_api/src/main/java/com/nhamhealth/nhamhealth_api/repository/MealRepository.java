package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.nhamhealth.nhamhealth_api.entity.Meal;

public interface MealRepository extends JpaRepository<Meal, Integer> {

    @Override
    Page<Meal> findAll(Pageable pageable);

    @Query("""
            select meal from Meal meal
            where (:search = '' or lower(meal.mealName) like concat('%', :search, '%'))
              and (:category = '' or lower(meal.category.categoryName) = :category)
              and (:status = '' or (:status = 'published' and meal.isPublished = true)
                  or (:status = 'draft' and meal.isPublished = false))
              and (:tag = '' or exists (
                    select mealTag from MealTag mealTag
                    where mealTag.meal = meal and lower(mealTag.tag.tagName) = :tag))
            """)
    Page<Meal> findForAdmin(
            @Param("search") String search,
            @Param("category") String category,
            @Param("status") String status,
            @Param("tag") String tag,
            Pageable pageable);

    List<Meal> findAllByOrderByUpdatedAtDesc();

    List<Meal> findAllByIsPublishedTrueOrderByMealNameAsc();

    long countByIsPublishedTrue();

    @Query("select m.category.categoryId, count(m) from Meal m group by m.category.categoryId")
    List<Object[]> countMealsByCategory();

    long countByCategoryCategoryId(Integer categoryId);
}
