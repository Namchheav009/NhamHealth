package com.nhamhealth.nhamhealth_api.controller.admin;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Comparator;
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

import com.nhamhealth.nhamhealth_api.entity.DailyWellnessSummary;
import com.nhamhealth.nhamhealth_api.entity.Mood;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.DailyWellnessSummaryRepository;
import com.nhamhealth.nhamhealth_api.repository.MoodRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;

@Controller
public class DailyWellnessAdminController {
    private final DailyWellnessSummaryRepository summaryRepository;
    private final UserRepository userRepository;
    private final MoodRepository moodRepository;

    public DailyWellnessAdminController(DailyWellnessSummaryRepository summaryRepository,
            UserRepository userRepository, MoodRepository moodRepository) {
        this.summaryRepository = summaryRepository;
        this.userRepository = userRepository;
        this.moodRepository = moodRepository;
    }

    @GetMapping("/admin/daily-wellness")
    public String wellnessPage(Authentication authentication, Model model) {
        List<DailyWellnessSummary> summaries = summaryRepository.findAllByOrderBySummaryDateDesc();
        long wellnessUsers = summaries.stream().map(DailyWellnessSummary::getUser).filter(Objects::nonNull)
                .map(User::getUserId).distinct().count();
        long insights = summaries.stream().map(DailyWellnessSummary::getAiInsightText)
                .filter(text -> text != null && !text.isBlank()).count();
        long todayEntries = summaries.stream().filter(summary -> LocalDate.now().equals(summary.getSummaryDate())).count();
        List<User> users = userRepository.findAll().stream()
                .sorted(Comparator.comparing(User::getName, String.CASE_INSENSITIVE_ORDER)).toList();
        List<Mood> moods = moodRepository.findAllByOrderByMoodNameAsc().stream()
                .filter(mood -> Boolean.TRUE.equals(mood.getIsActive())).toList();
        List<String> balances = summaries.stream().map(DailyWellnessSummary::getBalanceStatus)
                .filter(value -> value != null && !value.isBlank()).distinct().sorted().toList();

        model.addAttribute("pageTitle", "Daily Wellness");
        model.addAttribute("activePage", "daily-wellness");
        model.addAttribute("adminName", authentication.getName());
        model.addAttribute("wellnessSummaries", summaries);
        model.addAttribute("users", users);
        model.addAttribute("moods", moods);
        model.addAttribute("balanceStatuses", balances);
        model.addAttribute("totalEntries", summaries.size());
        model.addAttribute("uniqueUsers", wellnessUsers);
        model.addAttribute("insightCount", insights);
        model.addAttribute("todayEntries", todayEntries);
        return "admin/daily-wellness";
    }

    @PostMapping("/admin/daily-wellness")
    public String createSummary(@RequestParam Integer userId, @RequestParam LocalDate summaryDate,
            @RequestParam(required = false) Integer moodId, @RequestParam(required = false) String balanceStatus,
            @RequestParam(required = false) String aiInsightText, RedirectAttributes redirectAttributes) {
        if (summaryRepository.existsByUserUserIdAndSummaryDate(userId, summaryDate)) {
            redirectAttributes.addFlashAttribute("errorMessage", "That user already has a wellness summary for this date.");
            return "redirect:/admin/daily-wellness";
        }
        DailyWellnessSummary summary = new DailyWellnessSummary();
        summary.setUser(userRepository.findById(userId).orElseThrow());
        if (moodId != null) summary.setMood(moodRepository.findById(moodId).orElseThrow());
        summary.setSummaryDate(summaryDate);
        summary.setBalanceStatus(clean(balanceStatus));
        summary.setAiInsightText(clean(aiInsightText));
        summary.setCreatedAt(LocalDateTime.now());
        summary.setUpdatedAt(LocalDateTime.now());
        summaryRepository.save(summary);
        redirectAttributes.addFlashAttribute("successMessage", "Daily wellness summary added successfully.");
        return "redirect:/admin/daily-wellness";
    }

    @DeleteMapping("/admin/daily-wellness/{summaryId}")
    public ResponseEntity<Void> deleteSummary(@PathVariable Integer summaryId) {
        if (!summaryRepository.existsById(summaryId)) return ResponseEntity.notFound().build();
        summaryRepository.deleteById(summaryId);
        return ResponseEntity.noContent().build();
    }

    private String clean(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
