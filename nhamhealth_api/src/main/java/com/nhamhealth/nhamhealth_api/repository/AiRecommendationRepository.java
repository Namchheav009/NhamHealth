package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;
import java.util.Optional;
import java.time.LocalDateTime;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.AiRecommendation;

public interface AiRecommendationRepository extends JpaRepository<AiRecommendation, Integer> {

    List<AiRecommendation> findAllByOrderByCreatedAtDesc();

    Optional<AiRecommendation> findFirstByUserUserIdAndMoodMoodIdAndStatusOrderByCreatedAtDesc(
            Integer userId, Integer moodId, String status);

    Optional<AiRecommendation> findFirstByUserUserIdAndMoodMoodIdAndStatusAndCreatedAtGreaterThanEqualOrderByCreatedAtDesc(
            Integer userId, Integer moodId, String status, LocalDateTime createdAfter);

    Optional<AiRecommendation> findFirstByUserUserIdAndStatusOrderByCreatedAtDesc(
            Integer userId, String status);
}
