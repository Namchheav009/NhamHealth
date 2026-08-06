package com.nhamhealth.nhamhealth_api.controller.admin;

import java.util.List;
import java.util.Objects;

import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import com.nhamhealth.nhamhealth_api.entity.MealLog;
import com.nhamhealth.nhamhealth_api.repository.MealLogRepository;

@Controller
public class MealLogAdminController {

    private final MealLogRepository mealLogRepository;

    public MealLogAdminController(MealLogRepository mealLogRepository) {
        this.mealLogRepository = mealLogRepository;
    }

    @GetMapping("/admin/meal-logs")
    public String mealLogsPage(Authentication authentication, Model model) {
        List<MealLog> mealLogs = mealLogRepository.findAllByOrderByLoggedAtDesc();

        long uniqueUserCount = mealLogs.stream()
                .map(log -> log.getUser() != null ? log.getUser().getUserId() : null)
                .filter(Objects::nonNull)
                .distinct()
                .count();

        long customFoodCount = mealLogs.stream()
                .map(log -> log.getCustomFoodName())
                .filter(name -> name != null && !name.isBlank())
                .count();

        model.addAttribute("pageTitle", "Meal Logs");
        model.addAttribute("activePage", "meal-logs");
        model.addAttribute("adminName", authentication.getName());
        model.addAttribute("mealLogs", mealLogs);
        model.addAttribute("totalLogs", mealLogs.size());
        model.addAttribute("uniqueUsers", uniqueUserCount);
        model.addAttribute("customFoodCount", customFoodCount);

        return "admin/meals-log";
    }
}
