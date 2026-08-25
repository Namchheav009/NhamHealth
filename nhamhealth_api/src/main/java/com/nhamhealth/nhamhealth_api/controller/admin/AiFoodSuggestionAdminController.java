package com.nhamhealth.nhamhealth_api.controller.admin;

import java.util.List;
import java.util.Map;
import java.util.Objects;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.nhamhealth.nhamhealth_api.entity.AiFoodAnalysis;
import com.nhamhealth.nhamhealth_api.entity.AiFoodSuggestion;
import com.nhamhealth.nhamhealth_api.repository.AiFoodAnalysisRepository;
import com.nhamhealth.nhamhealth_api.repository.AiFoodSuggestionRepository;
import com.nhamhealth.nhamhealth_api.service.FoodCorrectionSuggestionService;

@Controller
public class AiFoodSuggestionAdminController {
    private final AiFoodSuggestionRepository suggestionRepository;
    private final AiFoodAnalysisRepository analysisRepository;
    private final FoodCorrectionSuggestionService correctionSuggestionService;

    public AiFoodSuggestionAdminController(AiFoodSuggestionRepository suggestionRepository,
            AiFoodAnalysisRepository analysisRepository,
            FoodCorrectionSuggestionService correctionSuggestionService) {
        this.suggestionRepository = suggestionRepository;
        this.analysisRepository = analysisRepository;
        this.correctionSuggestionService = correctionSuggestionService;
    }

    @GetMapping("/admin/ai-food-suggestions")
    public String aiFoodSuggestionsPage(Authentication authentication, Model model) {
        List<AiFoodSuggestion> suggestions = suggestionRepository.findAllByOrderByPriorityDesc();
        long uniqueRequests = suggestions.stream().map(AiFoodSuggestion::getAiFoodAnalysis)
                .filter(Objects::nonNull).map(analysis -> analysis.getAiFoodAnalysisId()).distinct().count();
        long highPriority = suggestions.stream().filter(s -> s.getPriority() != null && s.getPriority() >= 8).count();
        long learnedCorrections = suggestions.stream()
                .filter(suggestion -> FoodCorrectionSuggestionService.SUGGESTION_TYPE
                        .equalsIgnoreCase(suggestion.getSuggestionType()))
                .count();
        List<String> types = suggestions.stream().map(AiFoodSuggestion::getSuggestionType)
                .filter(value -> value != null && !value.isBlank()).distinct().sorted().toList();

        model.addAttribute("pageTitle", "AI Food Suggestions");
        model.addAttribute("activePage", "ai-food-suggestions");
        model.addAttribute("adminName", authentication.getName());
        model.addAttribute("aiSuggestions", suggestions);
        model.addAttribute("aiAnalyses", analysisRepository.findAllByOrderByCreatedAtDesc());
        model.addAttribute("suggestionTypes", types);
        model.addAttribute("totalSuggestions", suggestions.size());
        model.addAttribute("uniqueRequests", uniqueRequests);
        model.addAttribute("highPrioritySuggestions", highPriority);
        model.addAttribute("learnedCorrections", learnedCorrections);
        return "admin/ai-food-suggestion";
    }

    @PostMapping("/admin/ai-food-suggestions")
    @ResponseBody
    public ResponseEntity<?> createSuggestion(@RequestParam Integer analysisId, @RequestParam String suggestionType,
            @RequestParam String title, @RequestParam String description,
            @RequestParam(required = false) String reason, @RequestParam Integer priority) {
        if (suggestionType.isBlank() || title.isBlank() || description.isBlank() || priority < 1 || priority > 10) {
            return ResponseEntity.badRequest().body(Map.of(
                    "message", "Complete the required fields and use priority 1–10."));
        }
        if (suggestionType.trim().length() > 50 || title.trim().length() > 150
                || description.trim().length() > 255
                || (reason != null && reason.trim().length() > 255)) {
            return ResponseEntity.badRequest().body(Map.of(
                    "message", "Suggestion type, title, description, or reason is too long."));
        }
        AiFoodAnalysis analysis = analysisRepository.findById(analysisId).orElse(null);
        if (analysis == null) {
            return ResponseEntity.badRequest().body(Map.of(
                    "message", "Select a valid source analysis."));
        }
        AiFoodSuggestion suggestion = new AiFoodSuggestion();
        suggestion.setAiFoodAnalysis(analysis);
        suggestion.setSuggestionType(suggestionType.trim());
        suggestion.setTitle(title.trim());
        suggestion.setDescription(description.trim());
        suggestion.setReason(reason == null || reason.isBlank() ? null : reason.trim());
        suggestion.setPriority(priority);
        AiFoodSuggestion saved = suggestionRepository.saveAndFlush(suggestion);
        correctionSuggestionService.invalidateLearnedCorrections();
        return ResponseEntity.ok(toResponse(saved));
    }

    @DeleteMapping("/admin/ai-food-suggestions/{suggestionId}")
    @ResponseBody
    public ResponseEntity<Void> deleteSuggestion(@PathVariable Integer suggestionId) {
        if (!suggestionRepository.existsById(suggestionId)) return ResponseEntity.notFound().build();
        suggestionRepository.deleteById(suggestionId);
        correctionSuggestionService.invalidateLearnedCorrections();
        return ResponseEntity.noContent().build();
    }

    private Map<String, Object> toResponse(AiFoodSuggestion suggestion) {
        AiFoodAnalysis analysis = suggestion.getAiFoodAnalysis();
        String sourceName = analysis.getDetectedFoodName() == null || analysis.getDetectedFoodName().isBlank()
                ? analysis.getInputText() : analysis.getDetectedFoodName();
        String correctedName = analysis.getCorrectedFoodName() == null
                || analysis.getCorrectedFoodName().isBlank()
                        ? suggestion.getTitle() : analysis.getCorrectedFoodName();
        String correctedServing = analysis.getCorrectedServingSize() == null
                ? "Not recorded"
                : analysis.getCorrectedServingSize().stripTrailingZeros().toPlainString() + " "
                        + safe(analysis.getCorrectedServingUnit(), "serving");
        return Map.ofEntries(
                Map.entry("id", suggestion.getAiFoodSuggestionId()),
                Map.entry("analysisId", analysis.getAiFoodAnalysisId()),
                Map.entry("sourceName", sourceName),
                Map.entry("detectedName", sourceName),
                Map.entry("correctedName", correctedName),
                Map.entry("correctedServing", correctedServing),
                Map.entry("analysisStatus", safe(analysis.getStatus(), "Unknown")),
                Map.entry("feedbackAt", analysis.getFeedbackAt() == null
                        ? "" : analysis.getFeedbackAt().toString()),
                Map.entry("modelName", safe(analysis.getModelName(), "Not recorded")),
                Map.entry("promptVersion", safe(analysis.getPromptVersion(), "Not recorded")),
                Map.entry("learnedCorrection", FoodCorrectionSuggestionService.SUGGESTION_TYPE
                        .equalsIgnoreCase(suggestion.getSuggestionType())),
                Map.entry("suggestionType", suggestion.getSuggestionType()),
                Map.entry("title", suggestion.getTitle()),
                Map.entry("description", suggestion.getDescription()),
                Map.entry("reason", suggestion.getReason() == null ? "" : suggestion.getReason()),
                Map.entry("priority", suggestion.getPriority()));
    }

    private String safe(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value.trim();
    }
}
