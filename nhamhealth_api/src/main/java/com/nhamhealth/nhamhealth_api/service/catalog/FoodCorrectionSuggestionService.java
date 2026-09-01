package com.nhamhealth.nhamhealth_api.service.catalog;

import java.math.BigDecimal;
import java.util.Optional;

import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.nhamhealth.nhamhealth_api.dto.request.AiFoodFeedbackRequest;
import com.nhamhealth.nhamhealth_api.entity.AiFoodAnalysis;
import com.nhamhealth.nhamhealth_api.entity.AiFoodSuggestion;
import com.nhamhealth.nhamhealth_api.repository.ai.AiFoodSuggestionRepository;

@Service
public class FoodCorrectionSuggestionService {
    public static final String SUGGESTION_TYPE = "User Correction";
    private static final String CACHE_NAME = "foodCorrectionMatches";

    private final AiFoodSuggestionRepository suggestionRepository;
    private final FoodNameNormalizer nameNormalizer;

    public FoodCorrectionSuggestionService(
            AiFoodSuggestionRepository suggestionRepository,
            FoodNameNormalizer nameNormalizer) {
        this.suggestionRepository = suggestionRepository;
        this.nameNormalizer = nameNormalizer;
    }

    @Transactional
    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public boolean recordCorrection(
            AiFoodAnalysis analysis, AiFoodFeedbackRequest feedback) {
        Optional<AiFoodSuggestion> existing = suggestionRepository
                .findFirstByAiFoodAnalysis_AiFoodAnalysisIdAndSuggestionTypeIgnoreCaseOrderByAiFoodSuggestionIdDesc(
                        analysis.getAiFoodAnalysisId(), SUGGESTION_TYPE);
        String detectedName = displayName(analysis.getDetectedFoodName(), "Unknown food");
        String correctedName = feedback.foodName().trim();
        boolean nameChanged = !nameNormalizer.normalize(detectedName)
                .equals(nameNormalizer.normalize(correctedName));
        boolean servingChanged = !formatServing(feedback.servingSize(), feedback.servingUnit())
                .equalsIgnoreCase(displayName(analysis.getDetectedServingText(), ""));
        boolean isCorrection = !Boolean.TRUE.equals(feedback.confirmed())
                || nameChanged || servingChanged;

        if (!isCorrection) {
            existing.ifPresent(suggestionRepository::delete);
            return false;
        }

        AiFoodSuggestion suggestion = existing.orElseGet(AiFoodSuggestion::new);
        suggestion.setAiFoodAnalysis(analysis);
        suggestion.setSuggestionType(SUGGESTION_TYPE);
        suggestion.setTitle(correctedName);
        suggestion.setDescription(limit(
                "User changed the AI result from \"" + detectedName + "\" to \""
                        + correctedName + "\" and set the serving to "
                        + formatServing(feedback.servingSize(), feedback.servingUnit()) + ".",
                255));
        suggestion.setReason(
                "Saved from the AI Food Check edit-result screen. The corrected name is used "
                        + "as a learned alias for future nutrition-database matching.");
        suggestion.setPriority(9);
        suggestionRepository.save(suggestion);
        return true;
    }

    @Transactional(readOnly = true)
    @Cacheable(
            cacheNames = CACHE_NAME,
            key = "#detectedFoodName == null ? '' : #detectedFoodName.trim().toLowerCase()",
            sync = true)
    public Optional<String> findLearnedCorrection(String detectedFoodName) {
        String lookupName = nameNormalizer.normalize(detectedFoodName);
        if (lookupName.isBlank()) return Optional.empty();
        return suggestionRepository
                .findAllBySuggestionTypeIgnoreCaseOrderByAiFoodSuggestionIdDesc(SUGGESTION_TYPE)
                .stream()
                .filter(suggestion -> suggestion.getAiFoodAnalysis() != null)
                .filter(suggestion -> lookupName.equals(nameNormalizer.normalize(
                        suggestion.getAiFoodAnalysis().getDetectedFoodName())))
                .map(AiFoodSuggestion::getTitle)
                .filter(value -> value != null && !value.isBlank())
                .map(String::trim)
                .filter(value -> !lookupName.equals(nameNormalizer.normalize(value)))
                .findFirst();
    }

    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public void invalidateLearnedCorrections() {
        // Cache eviction is performed by the annotation.
    }

    private String formatServing(BigDecimal amount, String unit) {
        String formattedAmount = amount.stripTrailingZeros().toPlainString();
        String formattedUnit = displayName(unit, "serving");
        return formattedAmount + " " + formattedUnit;
    }

    private String displayName(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value.trim();
    }

    private String limit(String value, int maximum) {
        return value.length() <= maximum ? value : value.substring(0, maximum);
    }
}
