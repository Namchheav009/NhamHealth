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
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.nhamhealth.nhamhealth_api.entity.Nutrient;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.entity.UserNutrientGoal;
import com.nhamhealth.nhamhealth_api.repository.NutrientRepository;
import com.nhamhealth.nhamhealth_api.repository.UserNutrientGoalRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;

@Controller
public class NutrientGoalAdminController {

    private final UserNutrientGoalRepository goalRepository;
    private final UserRepository userRepository;
    private final NutrientRepository nutrientRepository;

    public NutrientGoalAdminController(UserNutrientGoalRepository goalRepository,
            UserRepository userRepository, NutrientRepository nutrientRepository) {
        this.goalRepository = goalRepository;
        this.userRepository = userRepository;
        this.nutrientRepository = nutrientRepository;
    }

    @GetMapping("/admin/nutrient-goals")
    public String nutrientGoalsPage(Authentication authentication, Model model) {
        List<UserNutrientGoal> goals = goalRepository.findAllByOrderByEffectiveFromDesc();
        LocalDate today = LocalDate.now();
        long activeGoals = goals.stream().filter(goal -> Boolean.TRUE.equals(goal.getIsActive())).count();
        long currentGoals = goals.stream().filter(goal -> Boolean.TRUE.equals(goal.getIsActive())
                && !goal.getEffectiveFrom().isAfter(today)
                && (goal.getEffectiveTo() == null || !goal.getEffectiveTo().isBefore(today))).count();
        long trackedNutrients = goals.stream().map(UserNutrientGoal::getNutrient)
                .filter(Objects::nonNull).map(Nutrient::getNutrientId).distinct().count();
        long usersWithGoals = goals.stream().map(UserNutrientGoal::getUser)
                .filter(Objects::nonNull).map(User::getUserId).distinct().count();

        List<User> users = userRepository.findAll().stream()
                .sorted(Comparator.comparing(User::getName, String.CASE_INSENSITIVE_ORDER)).toList();
        List<Nutrient> nutrients = nutrientRepository.findAllByOrderByDisplayOrderAsc();

        model.addAttribute("pageTitle", "Nutrient Goals");
        model.addAttribute("activePage", "nutrient-goals");
        model.addAttribute("adminName", authentication.getName());
        model.addAttribute("nutrientGoals", goals);
        model.addAttribute("users", users);
        model.addAttribute("nutrients", nutrients);
        model.addAttribute("totalGoals", goals.size());
        model.addAttribute("activeGoals", activeGoals);
        model.addAttribute("currentGoals", currentGoals);
        model.addAttribute("trackedNutrients", trackedNutrients);
        model.addAttribute("usersWithGoals", usersWithGoals);
        model.addAttribute("today", today);
        return "admin/nutrient-goal";
    }

    @PostMapping("/admin/nutrient-goals")
    @ResponseBody
    public ResponseEntity<?> createGoal(@RequestParam Integer userId, @RequestParam Integer nutrientId,
            @RequestParam BigDecimal goalAmount, @RequestParam LocalDate effectiveFrom,
            @RequestParam(required = false) LocalDate effectiveTo,
            @RequestParam(defaultValue = "true") Boolean active) {
        try {
            UserNutrientGoal goal = new UserNutrientGoal();
            apply(goal, userId, nutrientId, goalAmount, effectiveFrom, effectiveTo, active);
            LocalDateTime now = LocalDateTime.now();
            goal.setCreatedAt(now);
            goal.setUpdatedAt(now);
            return ResponseEntity.ok(toResponse(goalRepository.saveAndFlush(goal)));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.badRequest().body(Map.of("message", exception.getMessage()));
        }
    }

    @PutMapping("/admin/nutrient-goals/{goalId}")
    @ResponseBody
    public ResponseEntity<?> updateGoal(@PathVariable Integer goalId,
            @RequestParam Integer userId, @RequestParam Integer nutrientId,
            @RequestParam BigDecimal goalAmount, @RequestParam LocalDate effectiveFrom,
            @RequestParam(required = false) LocalDate effectiveTo,
            @RequestParam(defaultValue = "true") Boolean active) {
        UserNutrientGoal goal = goalRepository.findById(goalId).orElse(null);
        if (goal == null) return ResponseEntity.notFound().build();
        try {
            apply(goal, userId, nutrientId, goalAmount, effectiveFrom, effectiveTo, active);
            goal.setUpdatedAt(LocalDateTime.now());
            return ResponseEntity.ok(toResponse(goalRepository.saveAndFlush(goal)));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.badRequest().body(Map.of("message", exception.getMessage()));
        }
    }

    @DeleteMapping("/admin/nutrient-goals/{goalId}")
    @ResponseBody
    public ResponseEntity<Void> deleteGoal(@PathVariable Integer goalId) {
        if (!goalRepository.existsById(goalId)) return ResponseEntity.notFound().build();
        goalRepository.deleteById(goalId);
        return ResponseEntity.noContent().build();
    }

    private void apply(UserNutrientGoal goal, Integer userId, Integer nutrientId,
            BigDecimal goalAmount, LocalDate effectiveFrom, LocalDate effectiveTo, Boolean active) {
        if (goalAmount == null || goalAmount.signum() <= 0 || effectiveFrom == null
                || (effectiveTo != null && effectiveTo.isBefore(effectiveFrom))) {
            throw new IllegalArgumentException("Enter a positive goal and a valid date range.");
        }
        User user = userRepository.findById(userId).orElse(null);
        Nutrient nutrient = nutrientRepository.findById(nutrientId).orElse(null);
        if (user == null || nutrient == null) {
            throw new IllegalArgumentException("Select a valid user and nutrient.");
        }
        goal.setUser(user);
        goal.setNutrient(nutrient);
        goal.setGoalAmount(goalAmount);
        goal.setEffectiveFrom(effectiveFrom);
        goal.setEffectiveTo(effectiveTo);
        goal.setIsActive(Boolean.TRUE.equals(active));
    }

    private Map<String, Object> toResponse(UserNutrientGoal goal) {
        User user = goal.getUser();
        Nutrient nutrient = goal.getNutrient();
        return Map.ofEntries(
                Map.entry("id", goal.getUserNutrientGoalId()),
                Map.entry("userId", user.getUserId()),
                Map.entry("userName", nullSafe(user.getName())),
                Map.entry("userEmail", nullSafe(user.getEmail())),
                Map.entry("userInitials", nullSafe(user.getInitials())),
                Map.entry("nutrientId", nutrient.getNutrientId()),
                Map.entry("nutrientName", nutrient.getNutrientName()),
                Map.entry("unit", nullSafe(nutrient.getUnit())),
                Map.entry("goalAmount", goal.getGoalAmount()),
                Map.entry("effectiveFrom", goal.getEffectiveFrom().toString()),
                Map.entry("effectiveTo", goal.getEffectiveTo() == null ? "" : goal.getEffectiveTo().toString()),
                Map.entry("active", Boolean.TRUE.equals(goal.getIsActive())));
    }

    private String nullSafe(String value) {
        return value == null ? "" : value;
    }
}
