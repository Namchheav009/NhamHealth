package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.AiRecommendationItem;

public interface AiRecommendationItemRepository extends JpaRepository<AiRecommendationItem, Integer> {
    long countByRecommendationRecommendationId(Integer recommendationId);

    @EntityGraph(attributePaths = { "recommendation", "meal" })
    List<AiRecommendationItem> findAllByRecommendationRecommendationIdOrderByRankOrderAsc(Integer recommendationId);

    @EntityGraph(attributePaths = { "recommendation", "meal" })
    List<AiRecommendationItem> findAllByRecommendationRecommendationIdInOrderByRecommendationRecommendationIdAscRankOrderAsc(
            List<Integer> recommendationIds);

    void deleteByRecommendationRecommendationId(Integer recommendationId);
}
