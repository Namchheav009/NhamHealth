package com.nhamhealth.nhamhealth_api.repository.ai;

import java.util.List;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.AiRecommendationItem;

public interface AiRecommendationItemRepository extends JpaRepository<AiRecommendationItem, Integer> {
    @org.springframework.data.jpa.repository.Modifying
    @org.springframework.data.jpa.repository.Query("delete from AiRecommendationItem i where i.recommendation.recommendationId in (select r.recommendationId from AiRecommendation r where r.createdAt <= :cutoff)")
    int deleteExpired(@org.springframework.data.repository.query.Param("cutoff") java.time.LocalDateTime cutoff);

    long countByRecommendationRecommendationId(Integer recommendationId);

    @EntityGraph(attributePaths = { "recommendation", "meal" })
    List<AiRecommendationItem> findAllByRecommendationRecommendationIdOrderByRankOrderAsc(Integer recommendationId);

    @EntityGraph(attributePaths = { "recommendation", "meal" })
    List<AiRecommendationItem> findAllByRecommendationRecommendationIdInOrderByRecommendationRecommendationIdAscRankOrderAsc(
            List<Integer> recommendationIds);

    void deleteByRecommendationRecommendationId(Integer recommendationId);
}
