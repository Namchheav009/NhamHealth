package com.nhamhealth.nhamhealth_api.repository.ai;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.AiFoodAnalysis;

public interface AiFoodAnalysisRepository extends JpaRepository<AiFoodAnalysis, Integer> {

    @EntityGraph(attributePaths = "user")
    List<AiFoodAnalysis> findAllByOrderByCreatedAtDesc();
    Optional<AiFoodAnalysis> findByAiFoodAnalysisIdAndUserUserId(Integer analysisId, Integer userId);
}
