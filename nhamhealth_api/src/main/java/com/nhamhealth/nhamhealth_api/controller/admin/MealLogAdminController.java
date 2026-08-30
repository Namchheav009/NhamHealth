package com.nhamhealth.nhamhealth_api.controller.admin;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseBody;

import com.nhamhealth.nhamhealth_api.dto.request.AdminMealLogRequest;
import com.nhamhealth.nhamhealth_api.dto.response.AdminMealLogDto;
import com.nhamhealth.nhamhealth_api.entity.Meal;
import com.nhamhealth.nhamhealth_api.entity.MealLog;
import com.nhamhealth.nhamhealth_api.entity.MealLogType;
import com.nhamhealth.nhamhealth_api.entity.ServingSize;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.MealLogTypeRepository;
import com.nhamhealth.nhamhealth_api.repository.MealLogRepository;
import com.nhamhealth.nhamhealth_api.repository.MealLogNutrientRepository;
import com.nhamhealth.nhamhealth_api.repository.MealRepository;
import com.nhamhealth.nhamhealth_api.repository.ServingSizeRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;

import jakarta.transaction.Transactional;
import jakarta.validation.Valid;

@Controller
public class MealLogAdminController {

    private final MealLogRepository mealLogRepository;
    private final MealLogNutrientRepository mealLogNutrientRepository;
    private final UserRepository userRepository;
    private final MealLogTypeRepository mealLogTypeRepository;
    private final MealRepository mealRepository;
    private final ServingSizeRepository servingSizeRepository;

    public MealLogAdminController(MealLogRepository mealLogRepository,
            MealLogNutrientRepository mealLogNutrientRepository,
            UserRepository userRepository,
            MealLogTypeRepository mealLogTypeRepository,
            MealRepository mealRepository,
            ServingSizeRepository servingSizeRepository) {
        this.mealLogRepository = mealLogRepository;
        this.mealLogNutrientRepository = mealLogNutrientRepository;
        this.userRepository = userRepository;
        this.mealLogTypeRepository = mealLogTypeRepository;
        this.mealRepository = mealRepository;
        this.servingSizeRepository = servingSizeRepository;
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
        model.addAttribute("users", userRepository.findAll().stream()
                .sorted((left, right) -> left.getName().compareToIgnoreCase(right.getName())).toList());
        model.addAttribute("mealLogTypeOptions", mealLogTypeRepository.findAllByOrderBySortOrderAsc());
        model.addAttribute("meals", mealRepository.findAllByOrderByUpdatedAtDesc().stream()
                .sorted((left, right) -> left.getMealName().compareToIgnoreCase(right.getMealName())).toList());
        model.addAttribute("servingSizes", servingSizeRepository.findAllByOrderByServingSizeNameAsc());

        return "admin/meals-log";
    }

    @GetMapping("/admin/meal-logs/{mealLogId}")
    @ResponseBody
    public ResponseEntity<?> getMealLog(@PathVariable Integer mealLogId) {
        return mealLogRepository.findById(mealLogId)
                .<ResponseEntity<?>>map(log -> ResponseEntity.ok(toDto(log)))
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @PostMapping("/admin/meal-logs")
    @ResponseBody
    @Transactional
    public ResponseEntity<?> createMealLog(@Valid @RequestBody AdminMealLogRequest request) {
        try {
            MealLog mealLog = new MealLog();
            apply(mealLog, request);
            LocalDateTime now = LocalDateTime.now();
            mealLog.setCreatedAt(now);
            mealLog.setUpdatedAt(now);
            return ResponseEntity.status(201).body(toDto(mealLogRepository.save(mealLog)));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.badRequest().body(Map.of("message", exception.getMessage()));
        }
    }

    @PutMapping("/admin/meal-logs/{mealLogId}")
    @ResponseBody
    @Transactional
    public ResponseEntity<?> updateMealLog(@PathVariable Integer mealLogId,
            @Valid @RequestBody AdminMealLogRequest request) {
        try {
            MealLog mealLog = mealLogRepository.findById(mealLogId)
                    .orElseThrow(() -> new IllegalArgumentException("Meal log not found"));
            apply(mealLog, request);
            mealLog.setUpdatedAt(LocalDateTime.now());
            return ResponseEntity.ok(toDto(mealLogRepository.save(mealLog)));
        } catch (IllegalArgumentException exception) {
            if ("Meal log not found".equals(exception.getMessage())) {
                return ResponseEntity.notFound().build();
            }
            return ResponseEntity.badRequest().body(Map.of("message", exception.getMessage()));
        }
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

    private void apply(MealLog mealLog, AdminMealLogRequest request) {
        User user = userRepository.findById(request.userId())
                .orElseThrow(() -> new IllegalArgumentException("Selected user was not found"));
        MealLogType mealLogType = mealLogTypeRepository.findById(request.mealLogTypeId())
                .orElseThrow(() -> new IllegalArgumentException("Selected meal type was not found"));
        Meal meal = request.mealId() == null ? null : mealRepository.findById(request.mealId())
                .orElseThrow(() -> new IllegalArgumentException("Selected meal was not found"));
        ServingSize servingSize = request.servingSizeId() == null ? null
                : servingSizeRepository.findById(request.servingSizeId())
                        .orElseThrow(() -> new IllegalArgumentException("Selected serving size was not found"));

        mealLog.setUser(user);
        mealLog.setMealLogType(mealLogType);
        mealLog.setMeal(meal);
        mealLog.setServingSize(servingSize);
        mealLog.setCustomFoodName(meal == null ? trimToNull(request.customFoodName()) : null);
        mealLog.setQuantity(request.quantity());
        mealLog.setEntryMethod(request.entryMethod().trim());
        mealLog.setLoggedAt(request.loggedAt());
        mealLog.setNotes(trimToNull(request.notes()));
    }

    private AdminMealLogDto toDto(MealLog mealLog) {
        return new AdminMealLogDto(
                mealLog.getMealLogId(),
                mealLog.getUser() == null ? null : mealLog.getUser().getUserId(),
                mealLog.getMealLogType() == null ? null : mealLog.getMealLogType().getMealLogTypeId(),
                mealLog.getMeal() == null ? null : mealLog.getMeal().getMealId(),
                mealLog.getServingSize() == null ? null : mealLog.getServingSize().getServingSizeId(),
                mealLog.getCustomFoodName(),
                mealLog.getQuantity(),
                mealLog.getEntryMethod(),
                mealLog.getLoggedAt(),
                mealLog.getNotes());
    }

    private String trimToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
