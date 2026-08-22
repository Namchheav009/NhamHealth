package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.nhamhealth.nhamhealth_api.entity.Review;

public interface ReviewRepository extends JpaRepository<Review, Integer> {

    @Query(value = "SELECT COALESCE(AVG(rating), 0) FROM reviews", nativeQuery = true)
    double findAverageRating();

    List<Review> findByMealMealId(Integer mealId);

    List<Review> findAllByOrderByCreatedAtDesc();

    @EntityGraph(attributePaths = { "meal", "user" })
    List<Review> findTop5ByOrderByCreatedAtDesc();

    @Query("""
            select r.meal.mealId, avg(r.rating)
            from Review r
            where r.meal.mealId in :mealIds
            group by r.meal.mealId
            """)
    List<Object[]> findAverageRatingsByMealIds(@Param("mealIds") List<Integer> mealIds);
}
