package com.nhamhealth.nhamhealth_api.controller.admin;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

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
        LocalDate today = LocalDate.now();
        long todayCount = analyses.stream().filter(a -> a.getCreatedAt() != null
                && today.equals(a.getCreatedAt().toLocalDate())).count();
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
        model.addAttribute("today", today);
        return "admin/ai-food-analysis";
    }

    @PostMapping("/admin/ai-food-analyses")
    @ResponseBody
    public ResponseEntity<?> createAnalysis(@RequestParam Integer userId, @RequestParam String inputText,
            @RequestParam(required = false) String detectedFoodName,
            @RequestParam(required = false) String detectedServingText,
            @RequestParam(required = false) BigDecimal confidenceScore,
            @RequestParam(defaultValue = "pending") String status) {
        if (inputText.isBlank() || (confidenceScore != null
                && (confidenceScore.compareTo(BigDecimal.ZERO) < 0 || confidenceScore.compareTo(BigDecimal.ONE) > 0))) {
            return ResponseEntity.badRequest().body(Map.of(
                    "message", "Provide food input and a confidence value from 0 to 1."));
        }
        User user = userRepository.findById(userId).orElse(null);
        String normalizedStatus = status == null ? "pending" : status.trim().toLowerCase();
        if (user == null || !List.of("pending", "completed", "failed").contains(normalizedStatus)) {
            return ResponseEntity.badRequest().body(Map.of(
                    "message", "Select a valid user and analysis status."));
        }
        AiFoodAnalysis analysis = new AiFoodAnalysis();
        analysis.setUser(user);
        analysis.setInputText(inputText.trim());
        analysis.setDetectedFoodName(clean(detectedFoodName));
        analysis.setDetectedServingText(clean(detectedServingText));
        analysis.setConfidenceScore(confidenceScore);
        analysis.setStatus(normalizedStatus);
        analysis.setCreatedAt(LocalDateTime.now());
        return ResponseEntity.ok(toResponse(analysisRepository.saveAndFlush(analysis)));
    }

    private String clean(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private Map<String, Object> toResponse(AiFoodAnalysis analysis) {
        User user = analysis.getUser();
        return Map.ofEntries(
                Map.entry("id", analysis.getAiFoodAnalysisId()),
                Map.entry("userId", user.getUserId()),
                Map.entry("userName", nullSafe(user.getName())),
                Map.entry("userEmail", nullSafe(user.getEmail())),
                Map.entry("userInitials", nullSafe(user.getInitials())),
                Map.entry("inputText", analysis.getInputText()),
                Map.entry("detectedFoodName", nullSafe(analysis.getDetectedFoodName())),
                Map.entry("detectedServingText", nullSafe(analysis.getDetectedServingText())),
                Map.entry("confidenceScore", analysis.getConfidenceScore() == null ? "" : analysis.getConfidenceScore()),
                Map.entry("status", analysis.getStatus()),
                Map.entry("createdAt", analysis.getCreatedAt().toString()));
    }

    private String nullSafe(String value) {
        return value == null ? "" : value;
    }
}
