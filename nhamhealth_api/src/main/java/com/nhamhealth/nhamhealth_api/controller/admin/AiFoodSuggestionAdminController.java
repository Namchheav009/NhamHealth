package com.nhamhealth.nhamhealth_api.controller.admin;

import java.util.List;
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
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.nhamhealth.nhamhealth_api.entity.AiFoodSuggestion;
import com.nhamhealth.nhamhealth_api.repository.AiFoodAnalysisRepository;
import com.nhamhealth.nhamhealth_api.repository.AiFoodSuggestionRepository;

@Controller
public class AiFoodSuggestionAdminController {
    private final AiFoodSuggestionRepository suggestionRepository;
    private final AiFoodAnalysisRepository analysisRepository;

    public AiFoodSuggestionAdminController(AiFoodSuggestionRepository suggestionRepository,
            AiFoodAnalysisRepository analysisRepository) {
        this.suggestionRepository = suggestionRepository;
        this.analysisRepository = analysisRepository;
    }

    @GetMapping("/admin/ai-food-suggestions")
    public String aiFoodSuggestionsPage(Authentication authentication, Model model) {
        List<AiFoodSuggestion> suggestions = suggestionRepository.findAllByOrderByPriorityDesc();
        long uniqueRequests = suggestions.stream().map(AiFoodSuggestion::getAiFoodAnalysis)
                .filter(Objects::nonNull).map(analysis -> analysis.getAiFoodAnalysisId()).distinct().count();
        long highPriority = suggestions.stream().filter(s -> s.getPriority() != null && s.getPriority() >= 8).count();
        double averagePriority = suggestions.stream().map(AiFoodSuggestion::getPriority).filter(Objects::nonNull)
                .mapToInt(Integer::intValue).average().orElse(0.0);
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
        model.addAttribute("averagePriority", String.format("%.1f", averagePriority));
        return "admin/ai-food-suggestion";
    }

    @PostMapping("/admin/ai-food-suggestions")
    public String createSuggestion(@RequestParam Integer analysisId, @RequestParam String suggestionType,
            @RequestParam String title, @RequestParam String description,
            @RequestParam(required = false) String reason, @RequestParam Integer priority,
            RedirectAttributes redirectAttributes) {
        if (suggestionType.isBlank() || title.isBlank() || description.isBlank() || priority < 1 || priority > 10) {
            redirectAttributes.addFlashAttribute("errorMessage", "Complete the required fields and use priority 1–10.");
            return "redirect:/admin/ai-food-suggestions";
        }
        AiFoodSuggestion suggestion = new AiFoodSuggestion();
        suggestion.setAiFoodAnalysis(analysisRepository.findById(analysisId).orElseThrow());
        suggestion.setSuggestionType(suggestionType.trim());
        suggestion.setTitle(title.trim());
        suggestion.setDescription(description.trim());
        suggestion.setReason(reason == null || reason.isBlank() ? null : reason.trim());
        suggestion.setPriority(priority);
        suggestionRepository.save(suggestion);
        redirectAttributes.addFlashAttribute("successMessage", "AI food suggestion added successfully.");
        return "redirect:/admin/ai-food-suggestions";
    }

    @DeleteMapping("/admin/ai-food-suggestions/{suggestionId}")
    public ResponseEntity<Void> deleteSuggestion(@PathVariable Integer suggestionId) {
        if (!suggestionRepository.existsById(suggestionId)) return ResponseEntity.notFound().build();
        suggestionRepository.deleteById(suggestionId);
        return ResponseEntity.noContent().build();
    }
}
