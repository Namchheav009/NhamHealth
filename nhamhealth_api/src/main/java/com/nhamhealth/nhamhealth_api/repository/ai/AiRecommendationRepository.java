package com.nhamhealth.nhamhealth_api.repository.ai;

import java.util.List;
import java.util.Optional;
import java.time.LocalDateTime;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.EntityGraph;

import com.nhamhealth.nhamhealth_api.entity.AiRecommendation;

public interface AiRecommendationRepository extends JpaRepository<AiRecommendation, Integer> {

    @EntityGraph(attributePaths = {"user", "mood"})
    List<AiRecommendation> findAllByOrderByCreatedAtDesc();

    @EntityGraph(attributePaths = "user")
    List<AiRecommendation> findTop5ByOrderByCreatedAtDesc();

    @EntityGraph(attributePaths = "mood")
    Optional<AiRecommendation> findFirstByUserUserIdAndMoodMoodIdAndStatusOrderByCreatedAtDesc(
            Integer userId, Integer moodId, String status);

    @EntityGraph(attributePaths = "mood")
    Optional<AiRecommendation> findFirstByUserUserIdAndMoodMoodIdAndStatusAndCreatedAtGreaterThanEqualOrderByCreatedAtDesc(
            Integer userId, Integer moodId, String status, LocalDateTime createdAfter);

    @EntityGraph(attributePaths = "mood")
    Optional<AiRecommendation> findFirstByUserUserIdAndMoodIsNullAndStatusAndCreatedAtGreaterThanEqualOrderByCreatedAtDesc(
            Integer userId, String status, LocalDateTime createdAfter);

    @EntityGraph(attributePaths = "mood")
    Optional<AiRecommendation> findFirstByUserUserIdAndStatusOrderByCreatedAtDesc(
            Integer userId, String status);
}
