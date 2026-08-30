package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.AiFoodSuggestion;

public interface AiFoodSuggestionRepository extends JpaRepository<AiFoodSuggestion, Integer> {

    @EntityGraph(attributePaths = "aiFoodAnalysis")
    List<AiFoodSuggestion> findAllByOrderByPriorityDesc();

    Optional<AiFoodSuggestion>
            findFirstByAiFoodAnalysis_AiFoodAnalysisIdAndSuggestionTypeIgnoreCaseOrderByAiFoodSuggestionIdDesc(
                    Integer analysisId, String suggestionType);

    @EntityGraph(attributePaths = "aiFoodAnalysis")
    List<AiFoodSuggestion> findAllBySuggestionTypeIgnoreCaseOrderByAiFoodSuggestionIdDesc(
            String suggestionType);
}
