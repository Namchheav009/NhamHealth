package com.nhamhealth.nhamhealth_api.controller.admin;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;

import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.nhamhealth.nhamhealth_api.entity.AiFoodAnalysis;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.AiFoodAnalysisRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;

@Controller
public class AiFoodAnalysisAdminController {
    private final AiFoodAnalysisRepository analysisRepository;
    private final UserRepository userRepository;

    public AiFoodAnalysisAdminController(AiFoodAnalysisRepository analysisRepository, UserRepository userRepository) {
        this.analysisRepository = analysisRepository;
        this.userRepository = userRepository;
    }

    @GetMapping("/admin/ai-food-analyses")
    public String aiFoodAnalysisPage(Authentication authentication, Model model) {
        List<AiFoodAnalysis> analyses = analysisRepository.findAllByOrderByCreatedAtDesc();
        long uniqueUsers = analyses.stream().map(AiFoodAnalysis::getUser).filter(Objects::nonNull)
                .map(User::getUserId).distinct().count();
        long pendingCount = analyses.stream().filter(a -> "pending".equalsIgnoreCase(a.getStatus())).count();
        long todayCount = analyses.stream().filter(a -> a.getCreatedAt() != null
                && LocalDate.now().equals(a.getCreatedAt().toLocalDate())).count();
        double averageConfidence = analyses.stream().map(AiFoodAnalysis::getConfidenceScore)
                .filter(Objects::nonNull).mapToDouble(BigDecimal::doubleValue).average().orElse(0.0);
        List<User> users = userRepository.findAll().stream()
                .sorted(Comparator.comparing(User::getName, String.CASE_INSENSITIVE_ORDER)).toList();
        List<String> statuses = analyses.stream().map(AiFoodAnalysis::getStatus)
                .filter(value -> value != null && !value.isBlank()).distinct().sorted().toList();

        model.addAttribute("pageTitle", "AI Food Analyses");
        model.addAttribute("activePage", "ai-food-analyses");
        model.addAttribute("adminName", authentication.getName());
        model.addAttribute("aiAnalyses", analyses);
        model.addAttribute("users", users);
        model.addAttribute("analysisStatuses", statuses);
        model.addAttribute("totalAnalyses", analyses.size());
        model.addAttribute("uniqueUsers", uniqueUsers);
        model.addAttribute("pendingAnalyses", pendingCount);
        model.addAttribute("todayAnalyses", todayCount);
        model.addAttribute("averageConfidence", String.format("%.1f%%", averageConfidence * 100));
        return "admin/ai-food-analysis";
    }

    @PostMapping("/admin/ai-food-analyses")
    public String createAnalysis(@RequestParam Integer userId, @RequestParam String inputText,
            @RequestParam(required = false) String detectedFoodName,
            @RequestParam(required = false) String detectedServingText,
            @RequestParam(required = false) BigDecimal confidenceScore,
            @RequestParam(defaultValue = "pending") String status, RedirectAttributes redirectAttributes) {
        if (inputText.isBlank() || (confidenceScore != null
                && (confidenceScore.compareTo(BigDecimal.ZERO) < 0 || confidenceScore.compareTo(BigDecimal.ONE) > 0))) {
            redirectAttributes.addFlashAttribute("errorMessage", "Provide food input and a confidence value from 0 to 1.");
            return "redirect:/admin/ai-food-analyses";
        }
        AiFoodAnalysis analysis = new AiFoodAnalysis();
        analysis.setUser(userRepository.findById(userId).orElseThrow());
        analysis.setInputText(inputText.trim());
        analysis.setDetectedFoodName(clean(detectedFoodName));
        analysis.setDetectedServingText(clean(detectedServingText));
        analysis.setConfidenceScore(confidenceScore);
        analysis.setStatus(status.trim().toLowerCase());
        analysis.setCreatedAt(LocalDateTime.now());
        analysisRepository.save(analysis);
        redirectAttributes.addFlashAttribute("successMessage", "AI food analysis added successfully.");
        return "redirect:/admin/ai-food-analyses";
    }

    private String clean(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
