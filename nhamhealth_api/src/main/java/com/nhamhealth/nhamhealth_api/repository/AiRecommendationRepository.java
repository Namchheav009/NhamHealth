package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.AiRecommendation;

public interface AiRecommendationRepository extends JpaRepository<AiRecommendation, Integer> {

    List<AiRecommendation> findAllByOrderByCreatedAtDesc();
}
