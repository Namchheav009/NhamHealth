package com.nhamhealth.nhamhealth_api.controller.admin;

import java.util.List;
import java.util.Objects;

import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import com.nhamhealth.nhamhealth_api.entity.AiRecommendation;
import com.nhamhealth.nhamhealth_api.repository.AiRecommendationRepository;

@Controller
public class AiRecommendationAdminController {

    private final AiRecommendationRepository aiRecommendationRepository;

    public AiRecommendationAdminController(AiRecommendationRepository aiRecommendationRepository) {
        this.aiRecommendationRepository = aiRecommendationRepository;
    }

    @GetMapping("/admin/ai-recommendations")
    public String aiRecommendationsPage(Authentication authentication, Model model) {
        List<AiRecommendation> recs = aiRecommendationRepository.findAllByOrderByCreatedAtDesc();

        long uniqueUsers = recs.stream()
                .map(r -> r.getUser() != null ? r.getUser().getUserId() : null)
                .filter(Objects::nonNull)
                .distinct()
                .count();

        // AiRecommendation currently does not expose an items collection.
        // Keep totalItems available for the template, defaulting to 0.
        long totalItems = 0L;

        model.addAttribute("pageTitle", "AI Recommendations");
        model.addAttribute("activePage", "ai-recommendations");
        model.addAttribute("adminName", authentication.getName());
        model.addAttribute("aiRecs", recs);
        model.addAttribute("totalRecs", recs.size());
        model.addAttribute("uniqueUsers", uniqueUsers);
        model.addAttribute("totalItems", totalItems);

        return "admin/ai-recommendation";
    }
}
