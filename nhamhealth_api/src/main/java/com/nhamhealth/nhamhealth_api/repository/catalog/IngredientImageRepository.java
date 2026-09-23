package com.nhamhealth.nhamhealth_api.repository.catalog;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.nhamhealth.nhamhealth_api.entity.IngredientImage;

@Repository
public interface IngredientImageRepository extends JpaRepository<IngredientImage, Integer> {

    List<IngredientImage> findByIngredientIngredientId(Integer ingredientId);

    List<IngredientImage> findByIngredientIngredientIdAndReviewStatus(Integer ingredientId, String reviewStatus);

    Optional<IngredientImage> findFirstByIngredientIngredientIdAndReviewStatusOrderByIngredientImageIdAsc(
            Integer ingredientId, String reviewStatus);

    Optional<IngredientImage> findFirstByIngredientIngredientIdAndIsPrimaryTrue(Integer ingredientId);

    boolean existsByIngredientIngredientIdAndReviewStatus(Integer ingredientId, String reviewStatus);
}

