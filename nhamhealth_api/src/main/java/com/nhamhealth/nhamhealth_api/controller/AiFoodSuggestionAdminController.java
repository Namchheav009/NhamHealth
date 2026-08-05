package com.nhamhealth.nhamhealth_api.controller;

import java.util.List;
import java.util.Objects;

import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import com.nhamhealth.nhamhealth_api.entity.AiFoodSuggestion;
import com.nhamhealth.nhamhealth_api.repository.AiFoodSuggestionRepository;

@Controller
public class AiFoodSuggestionAdminController {

    private final AiFoodSuggestionRepository aiFoodSuggestionRepository;

    public AiFoodSuggestionAdminController(AiFoodSuggestionRepository aiFoodSuggestionRepository) {
        this.aiFoodSuggestionRepository = aiFoodSuggestionRepository;
    }

    @GetMapping("/admin/ai-food-suggestions")
    public String aiFoodSuggestionsPage(Authentication authentication, Model model) {
        List<AiFoodSuggestion> suggestions = aiFoodSuggestionRepository.findAllByOrderByPriorityDesc();

        long uniqueRequests = suggestions.stream()
                .map(suggestion -> suggestion.getAiFoodAnalysis() != null
                        ? suggestion.getAiFoodAnalysis().getAiFoodAnalysisId()
                        : null)
                .filter(Objects::nonNull)
                .distinct()
                .count();

        model.addAttribute("pageTitle", "AI Food Suggestions");
        model.addAttribute("activePage", "ai-food-suggestions");
        model.addAttribute("adminName", authentication.getName());
        model.addAttribute("aiSuggestions", suggestions);
        model.addAttribute("totalSuggestions", suggestions.size());
        model.addAttribute("uniqueRequests", uniqueRequests);

        return "admin/ai-food-suggestion";
    }
}
