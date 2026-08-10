package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.Review;

public interface ReviewRepository extends JpaRepository<Review, Integer> {

    List<Review> findByMealMealId(Integer mealId);

    List<Review> findAllByOrderByCreatedAtDesc();
}
