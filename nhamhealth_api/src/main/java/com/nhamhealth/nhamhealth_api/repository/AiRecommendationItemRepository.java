package com.nhamhealth.nhamhealth_api.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.AiRecommendationItem;

public interface AiRecommendationItemRepository extends JpaRepository<AiRecommendationItem, Integer> {
    long countByRecommendationRecommendationId(Integer recommendationId);

    void deleteByRecommendationRecommendationId(Integer recommendationId);
}
