package com.nhamhealth.nhamhealth_api.service.catalog;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import com.nhamhealth.nhamhealth_api.dto.request.AiFoodFeedbackRequest;
import com.nhamhealth.nhamhealth_api.entity.AiFoodAnalysis;
import com.nhamhealth.nhamhealth_api.entity.AiFoodSuggestion;
import com.nhamhealth.nhamhealth_api.repository.ai.AiFoodSuggestionRepository;

class FoodCorrectionSuggestionServiceTests {

    @Test
    void storesAnEditedResultAsAUserCorrectionSuggestion() {
        AiFoodSuggestionRepository repository = mock(AiFoodSuggestionRepository.class);
        when(repository
                .findFirstByAiFoodAnalysis_AiFoodAnalysisIdAndSuggestionTypeIgnoreCaseOrderByAiFoodSuggestionIdDesc(
                        null, FoodCorrectionSuggestionService.SUGGESTION_TYPE))
                .thenReturn(Optional.empty());
        FoodCorrectionSuggestionService service = new FoodCorrectionSuggestionService(
                repository, new FoodNameNormalizer());
        AiFoodAnalysis analysis = analysis("Unknown tea", "1 serving");
        AiFoodFeedbackRequest correction = new AiFoodFeedbackRequest(
                false, "Thai Iced Tea", BigDecimal.valueOf(350), "ml");

        assertTrue(service.recordCorrection(analysis, correction));

        ArgumentCaptor<AiFoodSuggestion> saved = ArgumentCaptor.forClass(AiFoodSuggestion.class);
        verify(repository).save(saved.capture());
        assertEquals("User Correction", saved.getValue().getSuggestionType());
        assertEquals("Thai Iced Tea", saved.getValue().getTitle());
        assertEquals(9, saved.getValue().getPriority());
        assertTrue(saved.getValue().getDescription().contains("350 ml"));
        assertTrue(saved.getValue().getDescription().length() <= 255);
    }

    @Test
    void returnsTheNewestLearnedNameForFutureMatching() {
        AiFoodSuggestionRepository repository = mock(AiFoodSuggestionRepository.class);
        AiFoodAnalysis analysis = analysis("Unknown tea", "350 ml");
        AiFoodSuggestion suggestion = new AiFoodSuggestion();
        suggestion.setAiFoodAnalysis(analysis);
        suggestion.setSuggestionType(FoodCorrectionSuggestionService.SUGGESTION_TYPE);
        suggestion.setTitle("Thai Iced Tea");
        when(repository.findAllBySuggestionTypeIgnoreCaseOrderByAiFoodSuggestionIdDesc(
                FoodCorrectionSuggestionService.SUGGESTION_TYPE))
                .thenReturn(List.of(suggestion));
        FoodCorrectionSuggestionService service = new FoodCorrectionSuggestionService(
                repository, new FoodNameNormalizer());

        Optional<String> learned = service.findLearnedCorrection("unknown teas");

        assertEquals(Optional.of("Thai Iced Tea"), learned);
    }

    private AiFoodAnalysis analysis(String detectedName, String serving) {
        AiFoodAnalysis analysis = new AiFoodAnalysis();
        analysis.setDetectedFoodName(detectedName);
        analysis.setDetectedServingText(serving);
        return analysis;
    }
}
