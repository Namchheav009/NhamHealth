package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.nhamhealth.nhamhealth_api.entity.Meal;
import com.nhamhealth.nhamhealth_api.dto.response.MealAdminAggregateProjection;

public interface MealRepository extends JpaRepository<Meal, Integer> {

    @Override
    Page<Meal> findAll(Pageable pageable);

                @Query(value = """
                                                select meal.mealId as mealId,
                                                                         meal.mealName as mealName,
                                                                         category.categoryName as category,
                                                                         meal.mainImageUrl as mainImageUrl,
                                                                         meal.caloriesCached as calories,
                                                                         meal.servings as servings,
                                                                         meal.isPublished as published,
                                                                         meal.updatedAt as updatedAt,
                                                                         coalesce(avg(review.rating), 0) as rating,
                                                                         count(distinct review.reviewId) as reviewCount,
                                                                         count(distinct favorite.mealFavoriteId) as favorites
                                                from Meal meal
                                                left join meal.category category
                                                left join Review review on review.meal = meal
                                                left join MealFavorite favorite on favorite.meal = meal
            where (:search = '' or lower(meal.mealName) like concat('%', :search, '%'))
                                                        and (:category = '' or lower(category.categoryName) = :category)
              and (:status = '' or (:status = 'published' and meal.isPublished = true)
                  or (:status = 'draft' and meal.isPublished = false))
              and (:tag = '' or exists (
                    select mealTag from MealTag mealTag
                    where mealTag.meal = meal and lower(mealTag.tag.tagName) = :tag))
            group by meal.mealId, meal.mealName, category.categoryName, meal.mainImageUrl,
                     meal.caloriesCached, meal.servings, meal.isPublished, meal.updatedAt
            """, countQuery = """
            select count(meal)
            from Meal meal
            left join meal.category category
            where (:search = '' or lower(meal.mealName) like concat('%', :search, '%'))
              and (:category = '' or lower(category.categoryName) = :category)
              and (:status = '' or (:status = 'published' and meal.isPublished = true)
                  or (:status = 'draft' and meal.isPublished = false))
              and (:tag = '' or exists (
                    select mealTag from MealTag mealTag
                    where mealTag.meal = meal and lower(mealTag.tag.tagName) = :tag))
            """)
    Page<MealAdminAggregateProjection> findForAdmin(
            @Param("search") String search,
            @Param("category") String category,
            @Param("status") String status,
            @Param("tag") String tag,
            Pageable pageable);

    List<Meal> findAllByOrderByUpdatedAtDesc();

    List<Meal> findAllByIsPublishedTrueOrderByMealNameAsc();

    @EntityGraph(attributePaths = "category")
    @Query("""
            select meal from Meal meal
            where meal.isPublished = true
              and (:keyword = '' or lower(meal.mealName) like concat('%', lower(:keyword), '%')
                  or lower(meal.category.categoryName) like concat('%', lower(:keyword), '%'))
              and (:categoryId = 0 or meal.category.categoryId = :categoryId)
            order by meal.mealName asc
            """)
    List<Meal> findPublishedMeals(
            @Param("keyword") String keyword,
            @Param("categoryId") Integer categoryId);

    long countByIsPublishedTrue();

    @Query("select m.category.categoryId, count(m) from Meal m group by m.category.categoryId")
    List<Object[]> countMealsByCategory();

    long countByCategoryCategoryId(Integer categoryId);
}
