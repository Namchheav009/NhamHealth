package com.nhamhealth.nhamhealth_api.controller;

import java.math.BigDecimal;
import java.util.List;
import java.util.Objects;

import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import com.nhamhealth.nhamhealth_api.entity.AiFoodAnalysis;
import com.nhamhealth.nhamhealth_api.repository.AiFoodAnalysisRepository;

@Controller
public class AiFoodAnalysisAdminController {

    private final AiFoodAnalysisRepository aiFoodAnalysisRepository;

    public AiFoodAnalysisAdminController(AiFoodAnalysisRepository aiFoodAnalysisRepository) {
        this.aiFoodAnalysisRepository = aiFoodAnalysisRepository;
    }

    @GetMapping("/admin/ai-food-analyses")
    public String aiFoodAnalysisPage(Authentication authentication, Model model) {
        List<AiFoodAnalysis> analyses = aiFoodAnalysisRepository.findAllByOrderByCreatedAtDesc();

        long uniqueUsers = analyses.stream()
                .map(analysis -> analysis.getUser() != null ? analysis.getUser().getUserId() : null)
                .filter(Objects::nonNull)
                .distinct()
                .count();

        long pendingCount = analyses.stream()
                .filter(analysis -> analysis.getStatus() != null && analysis.getStatus().equalsIgnoreCase("pending"))
                .count();

        double averageConfidence = analyses.stream()
                .map(AiFoodAnalysis::getConfidenceScore)
                .filter(Objects::nonNull)
                .mapToDouble(BigDecimal::doubleValue)
                .average()
                .orElse(0.0);

        model.addAttribute("pageTitle", "AI Food Analyses");
        model.addAttribute("activePage", "ai-food-analyses");
        model.addAttribute("adminName", authentication.getName());
        model.addAttribute("aiAnalyses", analyses);
        model.addAttribute("totalAnalyses", analyses.size());
        model.addAttribute("uniqueUsers", uniqueUsers);
        model.addAttribute("pendingAnalyses", pendingCount);
        model.addAttribute("averageConfidence", String.format("%.1f%%", averageConfidence * 100));

        return "admin/ai-food-analysis";
    }
}
