package com.nhamhealth.nhamhealth_api.controller.admin;

import java.util.List;
import java.util.Objects;
import java.time.LocalDate;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.ResponseBody;

import com.nhamhealth.nhamhealth_api.entity.MealLog;
import com.nhamhealth.nhamhealth_api.repository.MealLogRepository;
import com.nhamhealth.nhamhealth_api.repository.MealLogNutrientRepository;

import jakarta.transaction.Transactional;

@Controller
public class MealLogAdminController {

    private final MealLogRepository mealLogRepository;
    private final MealLogNutrientRepository mealLogNutrientRepository;

    public MealLogAdminController(MealLogRepository mealLogRepository,
            MealLogNutrientRepository mealLogNutrientRepository) {
        this.mealLogRepository = mealLogRepository;
        this.mealLogNutrientRepository = mealLogNutrientRepository;
    }

    @GetMapping("/admin/meal-logs")
    public String mealLogsPage(Authentication authentication, Model model) {
        List<MealLog> mealLogs = mealLogRepository.findAllByOrderByLoggedAtDesc();
        LocalDate today = LocalDate.now();

        long uniqueUserCount = mealLogs.stream()
                .map(log -> log.getUser() != null ? log.getUser().getUserId() : null)
                .filter(Objects::nonNull)
                .distinct()
                .count();

        long customFoodCount = mealLogs.stream()
                .map(log -> log.getCustomFoodName())
                .filter(name -> name != null && !name.isBlank())
                .count();

        long todayCount = mealLogs.stream()
                .filter(log -> log.getLoggedAt() != null && log.getLoggedAt().toLocalDate().equals(today))
                .count();

        model.addAttribute("pageTitle", "Meal Logs");
        model.addAttribute("activePage", "meal-logs");
        model.addAttribute("adminName", authentication.getName());
        model.addAttribute("mealLogs", mealLogs);
        model.addAttribute("totalLogs", mealLogs.size());
        model.addAttribute("uniqueUsers", uniqueUserCount);
        model.addAttribute("customFoodCount", customFoodCount);
        model.addAttribute("todayCount", todayCount);
        model.addAttribute("today", today);
        model.addAttribute("mealLogTypes", mealLogs.stream()
                .map(log -> log.getMealLogType() != null ? log.getMealLogType().getMealLogTypeName() : null)
                .filter(Objects::nonNull).distinct().sorted().toList());
        model.addAttribute("entryMethods", mealLogs.stream()
                .map(MealLog::getEntryMethod).filter(Objects::nonNull).distinct().sorted().toList());

        return "admin/meals-log";
    }

    @DeleteMapping("/admin/meal-logs/{mealLogId}")
    @ResponseBody
    @Transactional
    public ResponseEntity<Void> deleteMealLog(@PathVariable Integer mealLogId) {
        if (!mealLogRepository.existsById(mealLogId)) {
            return ResponseEntity.notFound().build();
        }
        mealLogNutrientRepository.deleteByMealLogMealLogId(mealLogId);
        mealLogRepository.deleteById(mealLogId);
        return ResponseEntity.noContent().build();
    }
}
