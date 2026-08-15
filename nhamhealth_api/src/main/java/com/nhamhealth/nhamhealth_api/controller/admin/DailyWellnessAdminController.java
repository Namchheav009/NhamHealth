package com.nhamhealth.nhamhealth_api.controller.admin;

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
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.nhamhealth.nhamhealth_api.entity.DailyWellnessSummary;
import com.nhamhealth.nhamhealth_api.entity.Mood;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.DailyWellnessSummaryRepository;
import com.nhamhealth.nhamhealth_api.repository.DailyNutrientTotalRepository;
import com.nhamhealth.nhamhealth_api.repository.MoodRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;

import jakarta.transaction.Transactional;

@Controller
public class DailyWellnessAdminController {
    private final DailyWellnessSummaryRepository summaryRepository;
    private final UserRepository userRepository;
    private final MoodRepository moodRepository;
    private final DailyNutrientTotalRepository dailyNutrientTotalRepository;

    public DailyWellnessAdminController(DailyWellnessSummaryRepository summaryRepository,
            UserRepository userRepository, MoodRepository moodRepository,
            DailyNutrientTotalRepository dailyNutrientTotalRepository) {
        this.summaryRepository = summaryRepository;
        this.userRepository = userRepository;
        this.moodRepository = moodRepository;
        this.dailyNutrientTotalRepository = dailyNutrientTotalRepository;
    }

    @GetMapping("/admin/daily-wellness")
    public String wellnessPage(Authentication authentication, Model model) {
        List<DailyWellnessSummary> summaries = summaryRepository.findAllByOrderBySummaryDateDesc();
        long wellnessUsers = summaries.stream().map(DailyWellnessSummary::getUser).filter(Objects::nonNull)
                .map(User::getUserId).distinct().count();
        long insights = summaries.stream().map(DailyWellnessSummary::getAiInsightText)
                .filter(text -> text != null && !text.isBlank()).count();
        LocalDate today = LocalDate.now();
        long todayEntries = summaries.stream().filter(summary -> today.equals(summary.getSummaryDate())).count();
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
        model.addAttribute("today", today);
        return "admin/daily-wellness";
    }

    @PostMapping("/admin/daily-wellness")
    @ResponseBody
    public ResponseEntity<?> createSummary(@RequestParam Integer userId, @RequestParam LocalDate summaryDate,
            @RequestParam(required = false) Integer moodId, @RequestParam(required = false) String balanceStatus,
            @RequestParam(required = false) String aiInsightText) {
        if (summaryRepository.existsByUserUserIdAndSummaryDate(userId, summaryDate)) {
            return ResponseEntity.badRequest().body(Map.of(
                    "message", "That user already has a wellness summary for this date."));
        }
        User user = userRepository.findById(userId).orElse(null);
        Mood mood = moodId == null ? null : moodRepository.findById(moodId).orElse(null);
        if (user == null || (moodId != null && mood == null)) {
            return ResponseEntity.badRequest().body(Map.of(
                    "message", "Select a valid user and mood."));
        }
        DailyWellnessSummary summary = new DailyWellnessSummary();
        summary.setUser(user);
        summary.setMood(mood);
        summary.setSummaryDate(summaryDate);
        summary.setBalanceStatus(clean(balanceStatus));
        summary.setAiInsightText(clean(aiInsightText));
        summary.setCreatedAt(LocalDateTime.now());
        summary.setUpdatedAt(LocalDateTime.now());
        return ResponseEntity.ok(toResponse(summaryRepository.saveAndFlush(summary)));
    }

    @DeleteMapping("/admin/daily-wellness/{summaryId}")
    @ResponseBody
    @Transactional
    public ResponseEntity<Void> deleteSummary(@PathVariable Integer summaryId) {
        if (!summaryRepository.existsById(summaryId)) return ResponseEntity.notFound().build();
        dailyNutrientTotalRepository.deleteByDailyWellnessSummaryDailySummaryId(summaryId);
        summaryRepository.deleteById(summaryId);
        return ResponseEntity.noContent().build();
    }

    private String clean(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private Map<String, Object> toResponse(DailyWellnessSummary summary) {
        User user = summary.getUser();
        Mood mood = summary.getMood();
        return Map.ofEntries(
                Map.entry("id", summary.getDailySummaryId()),
                Map.entry("userId", user.getUserId()),
                Map.entry("userName", nullSafe(user.getName())),
                Map.entry("userEmail", nullSafe(user.getEmail())),
                Map.entry("userInitials", nullSafe(user.getInitials())),
                Map.entry("summaryDate", summary.getSummaryDate().toString()),
                Map.entry("moodId", mood == null ? 0 : mood.getMoodId()),
                Map.entry("moodName", mood == null ? "" : nullSafe(mood.getMoodName())),
                Map.entry("moodEmoji", mood == null ? "" : nullSafe(mood.getEmojiCode())),
                Map.entry("balanceStatus", nullSafe(summary.getBalanceStatus())),
                Map.entry("aiInsightText", nullSafe(summary.getAiInsightText())),
                Map.entry("updatedAt", summary.getUpdatedAt().toString()));
    }

    private String nullSafe(String value) {
        return value == null ? "" : value;
    }
}
