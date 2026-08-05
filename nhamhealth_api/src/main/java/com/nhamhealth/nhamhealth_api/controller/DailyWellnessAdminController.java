package com.nhamhealth.nhamhealth_api.controller;

import java.util.List;
import java.util.Objects;

import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import com.nhamhealth.nhamhealth_api.entity.DailyWellnessSummary;
import com.nhamhealth.nhamhealth_api.repository.DailyWellnessSummaryRepository;

@Controller
public class DailyWellnessAdminController {

    private final DailyWellnessSummaryRepository dailyWellnessSummaryRepository;

    public DailyWellnessAdminController(DailyWellnessSummaryRepository dailyWellnessSummaryRepository) {
        this.dailyWellnessSummaryRepository = dailyWellnessSummaryRepository;
    }

    @GetMapping("/admin/daily-wellness")
    public String wellnessPage(Authentication authentication, Model model) {
        List<DailyWellnessSummary> summaries = dailyWellnessSummaryRepository.findAllByOrderBySummaryDateDesc();
        long wellnessUsers = summaries.stream()
                .map(summary -> summary.getUser() != null ? summary.getUser().getUserId() : null)
                .filter(Objects::nonNull)
                .distinct()
                .count();

        model.addAttribute("pageTitle", "Daily Wellness");
        model.addAttribute("activePage", "daily-wellness");
        model.addAttribute("adminName", authentication.getName());
        model.addAttribute("wellnessSummaries", summaries);
        model.addAttribute("totalEntries", summaries.size());
        model.addAttribute("uniqueUsers", wellnessUsers);

        return "admin/daily-wellness";
    }
}
